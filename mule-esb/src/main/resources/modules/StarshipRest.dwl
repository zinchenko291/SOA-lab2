%dw 2.0
import try, orElse from dw::Runtime
import some from dw::core::Arrays
ns soap http://schemas.xmlsoap.org/soap/envelope/
ns starship urn:soa:starship:v1

fun restError(status, message, field = null) =
    {status: status, body: {status: status, message: message, field: field}}

fun unavailable() =
    restError(503, "SOAP-сервис временно недоступен")

fun badSoapResponse() =
    restError(502, "SOAP-сервис вернул некорректный ответ")

fun integer(value: String | Null) =
    if (value == null or not (trim(value) matches /[+-]?[0-9]+/)) null
    else do {
        var number = trim(value) as Number
        ---
        if (number >= -2147483648 and number <= 2147483647) number else null
    }

fun queryInteger(value: String | Null, fallback: Number) =
    if (value == null or value == "") fallback else integer(value)

fun pagination(query: Object) =
    {page: queryInteger(query.page, 0), size: queryInteger(query.size, 10)}

fun operation(path: String, query: Object) = do {
    var parts = (path replace /^\// with "") splitBy "/"
    var count = sizeOf(parts)
    var starshipId = integer(parts[3])
    ---
    if (parts[0] != "api" or parts[1] != "v1") null
    else if (count == 3 and parts[2] == "starships")
        {name: "getStarships", method: "GET", args: pagination(query)}
    else if (parts[2] != "starship" or isEmpty(parts[3])) null
    else if (count == 5 and parts[4] == "space-marines")
        {name: "getStarshipSpaceMarines", method: "GET",
            args: {starshipId: starshipId} ++ pagination(query),
            filters: query.*filter default []}
    else if (count == 6 and parts[4] == "load" and not isEmpty(parts[5]))
        {name: "loadSpaceMarine", method: "POST",
            args: {starshipId: starshipId, spaceMarineId: integer(parts[5])}}
    else if (count == 5 and parts[4] == "unload-all")
        {name: "unloadAll", method: "POST", args: {starshipId: starshipId}}
    else null
}

fun acceptsJson(header) =
    header == null or ((header splitBy ",") some ((entry) -> do {
        var parts = entry splitBy ";"
        var mediaType = lower(trim(parts[0]))
        ---
        ["application/json", "application/*", "*/*"] contains mediaType
    }))

fun allowedMethods(route) =
    if (route.method == "GET") "GET, HEAD, OPTIONS" else "POST, OPTIONS"

fun requestError(route, method, accept) =
    if (route == null) restError(404, "Запрашиваемый ресурс не найден")
    else if (method == "OPTIONS") {status: 200, body: null, headers: {Allow: allowedMethods(route)}}
    else if (method != route.method and not (route.method == "GET" and method == "HEAD"))
        restError(405, "HTTP-метод не поддерживается для данного адреса") ++
            {headers: {Allow: allowedMethods(route)}}
    else if (not acceptsJson(accept)) restError(406, "Запрошенный формат ответа не поддерживается")
    else if (valuesOf(route.args) contains null) restError(400, "Некорректное тело запроса или параметры")
    else null

fun soapRequest(route: Object) = {
    soap#Envelope: {
        soap#Body: (route.name match {
            case "getStarships" -> {starship#getStarships: route.args}
            case "getStarshipSpaceMarines" -> {
                starship#getStarshipSpaceMarines: (route.args as Object) ++ {
                    ((route.filters default []) map ((expression) -> {filter: expression}))
                }
            }
            case "loadSpaceMarine" -> {starship#loadSpaceMarine: route.args}
            case "unloadAll" -> {starship#unloadAll: route.args}
        })
    }
}

fun numberOrNull(value) = if (value == null) null else value as Number

fun marine(value) = {
    id: numberOrNull(value.id),
    name: value.name,
    coordinates: if (value.coordinates == null) null else {
        x: numberOrNull(value.coordinates.x),
        y: numberOrNull(value.coordinates.y)
    },
    creationDate: value.creationDate,
    health: numberOrNull(value.health),
    achievements: value.achievements,
    weaponType: value.weaponType,
    meleeWeapon: value.meleeWeapon,
    chapter: if (value.chapter == null) null else {
        name: value.chapter.name,
        parentLegion: value.chapter.parentLegion,
        world: value.chapter.world
    }
}

fun page(value, mapItem) = {
    content: (value.*content default []) map ((item) -> mapItem(item)),
    page: numberOrNull(value.page),
    size: numberOrNull(value.size),
    totalElements: numberOrNull(value.totalElements),
    totalPages: numberOrNull(value.totalPages)
}

fun soapReturn(body, name) = name match {
    case "getStarships" -> body.starship#getStarshipsResponse.return
    case "getStarshipSpaceMarines" -> body.starship#getStarshipSpaceMarinesResponse.return
    case "loadSpaceMarine" -> body.starship#loadSpaceMarineResponse.return
    case "unloadAll" -> body.starship#unloadAllResponse.return
}

fun successBody(value, name) = name match {
    case "getStarships" -> page(value, (ship) -> {id: ship.id as Number})
    case "getStarshipSpaceMarines" -> page(value, (item) -> marine(item))
    case "loadSpaceMarine" -> marine(value)
    case "unloadAll" -> value as Number
}

fun soapResponse(rawBody, httpStatus, name) =
    if (httpStatus == 503 or httpStatus == 504) unavailable()
    else (try(() -> do {
        var body = read(rawBody, "application/xml", {supportDtd: false, nullValueOn: "none"}).soap#Envelope.soap#Body
        var fault = body.soap#Fault.detail.starship#StarshipFault
        var faultStatus = numberOrNull(fault.status)
        var response = soapReturn(body, name)
        ---
        if (faultStatus != null and faultStatus >= 400 and faultStatus <= 599 and fault.message != null)
            restError(faultStatus, fault.message, fault.field)
        else if (httpStatus == 200 and response != null)
            {status: 200, body: successBody(response, name)}
        else badSoapResponse()
    }) orElse badSoapResponse())
