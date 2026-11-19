package soa.lab2.starship.dto;

public enum MeleeWeaponDTO {
    CHAIN_SWORD, CHAIN_AXE, POWER_BLADE, POWER_FIST;

    public static MeleeWeaponDTO fromValue(String value) {
        return valueOf(value);
    }

    public String getValue() {
        return name();
    }
}
