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

    speed = 0;
    damage = 0;
    radius = 0;

    // quick = fast but weaker
    // strong = slow but hits harder
    switch (spellPower)
    {
        case SpellPower.QUICK:
            speed = 10;
            damage = 8;
            radius = 10;
        break;

        case SpellPower.MEDIUM:
            speed = 7;
            damage = 14;
            radius = 15;
        break;

        case SpellPower.STRONG:
            speed = 4;
            damage = 24;
            radius = 22;
        break;
    }
}