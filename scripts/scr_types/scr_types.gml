// This is the file we will store the shared types and data objects
// GameState tracks the part of the game we are currently in
// saves us from doing long string checks every time we want to do something 
enum GameState
{
    MENU,
    PLAYING,
    PAUSED,
    WON,
    LOST
}

// The spell enums not fully used yet
// They are here for clarity at the moment
enum SpellPower
{
    QUICK,
    MEDIUM,
    STRONG
}

enum SpellElement
{
    FIRE,
    WATER,
    AIR
}

enum SpellLane
{
    LOW,
    MIDDLE,
    HIGH
}

// simple config object for the prototype
// keeps room positions and lane positions out of random scripts
function PrototypeConfig() constructor
{
    roomWidth = 1280;
    roomHeight = 720;

    instanceLayer = "Instances";

    playerStartX = 160;
    enemyStartX = 1120;

    arenaTopY = 230;
    arenaBottomY = 650;

    // lanes
    laneHighY = 330;
    laneMiddleY = 455;
    laneLowY = 580;

    // wizards stand around the middle lane for now
    // later sprites can be offset if they need to stand on a ground line
    wizardY = laneMiddleY;

    maxFloor = 2;
}

// spell object exists in the room, this struct stores what kind of spell it is
function SpellData(_spellPower, _spellElement, _spellLane) constructor
{
    spellPower = _spellPower;
    spellElement = _spellElement;
    spellLane = _spellLane;

    // number version of the power
    // makes clash maths easier, quick = 1, medium = 2, strong = 3
    powerValue = spell_power_to_value(spellPower);

    var _stats = spell_get_stats_from_power_value(powerValue);

    speed = _stats.speed;
    damage = _stats.damage;
    radius = _stats.radius;
}

// turns spell enum into a simple number for clash maths
function spell_power_to_value(_spellPower)
{
    switch (_spellPower)
    {
        case SpellPower.QUICK:
            return 1;

        case SpellPower.MEDIUM:
            return 2;

        case SpellPower.STRONG:
            return 3;
    }

    return 1;
}

// turns a number back into the spell power enum
// useful when a strong spell gets reduced after a clash
function spell_value_to_power(_value)
{
    if (_value <= 1)
    {
        return SpellPower.QUICK;
    }

    if (_value == 2)
    {
        return SpellPower.MEDIUM;
    }

    return SpellPower.STRONG;
}

// keeps speed, damage and size tied to current power
// this lets reduced spells still behave correctly
function spell_get_stats_from_power_value(_powerValue)
{
    var _stats = {
        speed: 10,
        damage: 8,
        radius: 10
    };

    if (_powerValue == 2)
    {
        _stats.speed = 7;
        _stats.damage = 14;
        _stats.radius = 15;
    }
    else if (_powerValue >= 3)
    {
        _stats.speed = 4;
        _stats.damage = 24;
        _stats.radius = 22;
    }

    return _stats;
}