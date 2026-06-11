// This is the file we will store the shared types and data objects
// GameState tracks the part of the game we are currently in
// saves us from doing long string checks every time we want to do something 
enum GameState
{
    MENU,
    HELP,
    PRE_COMBAT,
    PLAYING,
    FLOOR_TRANSITION,
    PAUSED,
    PAUSE_HELP,
    WON,
    LOST
}

// spell power controls speed, damage, size, mana cost, and clash strength
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

// keeping this because our cast animations are still low/mid/high
// spells are not locked to lanes anymore though
enum SpellLane
{
    LOW,
    MIDDLE,
    HIGH
}

enum EnemyType
{
    TRAINING_DUMMY,
    GOBLIN,
	NOSY_AUNT,
    VEXATIOUS_FAIRY,
    BUTLER_WHITE,
    BUTLER_BLACK,
    BREAKNECK_GOLEM,
    TRAINED_DUMMY,
    NECROMANCER_ONE,
    NECROMANCER_TWO,
    NECROMANCER_THREE
}

// simple config object for the game
// keeps arena positions and shared numbers out of random scripts
function PrototypeConfig() constructor
{
    roomWidth = 1280;
    roomHeight = 720;

    instanceLayer = "Instances";
    dialogueLayer = "UI";

    playerStartX = 160;
    enemyStartX = 1120;

    // tighter movement area
    // higher top number = less upward movement
    arenaTopY = 440;
    arenaBottomY = 600;

    // these are just soft height references now
    // we do NOT draw lane highlights anymore
    // still useful for picking low/mid/high cast animations
    laneHighY = 400;
    laneMiddleY = 490;
    laneLowY = 580;

    // start around the middle of the fight area
    wizardY = laneMiddleY;

    // story floor count
    maxFloor = 8;

    // actual fight count, including phase fights
    // butlers and necromancer use extra entries for phases
    maxFight = 11;

    // background layers
    battleBackgroundLayer = "BattleBackground";
    topFloorStart = 8;
	
	// toggle for quickly testing floor flow
	debugInstaDefeat = true;
}

// spell object exists in the room, this struct stores what kind of spell it is
// spells do not store a lane now, they spawn from the caster's current height
function SpellData(_spellPower, _spellElement) constructor
{
    spellPower = _spellPower;
    spellElement = _spellElement;

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

// keeps speed, damage and fallback size tied to current power
// spell sprite bbox is used for actual collision when possible
function spell_get_stats_from_power_value(_powerValue)
{
    var _stats = {
        speed: 10,
        damage: 8,
        radius: 8
    };

    if (_powerValue == 2)
    {
        _stats.speed = 7;
        _stats.damage = 14;
        _stats.radius = 12;
    }
    else if (_powerValue >= 3)
    {
        _stats.speed = 4;
        _stats.damage = 24;
        _stats.radius = 16;
    }

    return _stats;
}

// scales characters based on how far down the screen they are
// top of arena = slightly smaller, bottom = full size
function depth_scale_from_y(_y)
{
    var _cfg = global.config;
    var _range = _cfg.arenaBottomY - _cfg.arenaTopY;

    if (_range <= 0)
    {
        return 1;
    }

    var _amount = (_y - _cfg.arenaTopY) / _range;
    _amount = clamp(_amount, 0, 1);

    // subtle depth feel
    // 0.88 at top, 1.0 at bottom
    return 0.88 + (0.12 * _amount);
}

// picks low/mid/high cast pose based on a y position
// this is only for choosing animation now
function cast_pose_from_y(_y)
{
    var _cfg = global.config;
    var _third = (_cfg.arenaBottomY - _cfg.arenaTopY) / 3;

    if (_y < _cfg.arenaTopY + _third)
    {
        return SpellLane.HIGH;
    }

    if (_y < _cfg.arenaTopY + (_third * 2))
    {
        return SpellLane.MIDDLE;
    }

    return SpellLane.LOW;
}
