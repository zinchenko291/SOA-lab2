# Starship: SOAP и REST-адаптер

Описание SOAP-контракта и первого этапа миграции находится в [docs/soap-migration.html](docs/soap-migration.html).

Вызывающий `starship-service` предоставляет SOAP 1.1 на `/services/starships` и WSDL на `/services/starships?wsdl`. Gateway направляет прежние REST-адреса Starship в Mule. Mule переводит REST в SOAP и отдельно проксирует вызовы Starship к REST API Collection.

## Локальный запуск (Windows / PowerShell)

Нужны JDK 21, Docker Desktop и Node.js 22.6+ для дополнительной проверки исходных клиентских TypeScript-схем. Maven скачивается wrapper-скриптом. Для сборки Mule положите архив `mule-standalone-4.9.0.tar.gz` в каталог `mule-esb/`.

```powershell
cd soa-front
npx --yes pnpm@10 install --frozen-lockfile
cd ..
.\scripts\start-local.ps1 -WithFrontend
```

Скрипт собирает приложения с тестами, запускает PostgreSQL и Mule в Docker, а Config Server, Eureka, Collection, SOAP Starship, gateway и фронтенд на хосте. Для повторного запуска с готовыми артефактами используйте `-SkipBuild`. Существующие процессы нужно сначала остановить.

- Клиент: http://localhost:3000/
- REST через gateway: http://localhost:18080/api/starship-service/starships
- REST напрямую: http://localhost:8083/api/v1/starships
- WSDL: http://localhost:8082/services/starships?wsdl

Проверка реальной цепочки:

```powershell
node scripts/test-e2e.mjs
# Проверка тех же ответов исходными Zod-схемами неизменённого клиента:
node --experimental-strip-types scripts/test-e2e.mjs --client-schemas
```

Остановка (данные локальной БД сохраняются):

```powershell
.\scripts\stop-local.ps1
```

Логи и PID-файлы: `.local-run/`; отчёт сквозных тестов: `.local-run/e2e-results.json`.

## Проверки

SOAP-контракт проверяется тестами Maven. Сквозной сценарий проверяет четыре REST-операции через gateway, преобразование ошибок, повторяющиеся фильтры и JSON-формат фронтенда.

## Docker с HTTPS

Для запуска нужны существующие сертификаты, переменные `TLS_STORE_PASSWORD` и `DB_PASSWORD` и архив Mule в `mule-esb/`. Gateway передаёт REST в Mule по HTTP внутри сети Docker. Mule вызывает SOAP по HTTPS через HAProxy и обращается к Collection по HTTPS. Чтобы при обновлении убрать контейнер старого REST-адаптера из проекта Compose, используйте `docker compose up --build -d --remove-orphans`.
