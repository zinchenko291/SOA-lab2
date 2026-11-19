package soa.lab2.starship.dto;

public enum WeaponDTO {
    COMBI_FLAMER, GRENADE_LAUNCHER, HEAVY_FLAMER;

    public static WeaponDTO fromValue(String value) {
        return valueOf(value);
    }

    public String getValue() {
        return name();
    }
}
