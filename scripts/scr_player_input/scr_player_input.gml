// handles arrow key spell combo input
// first arrow = power, second arrow = element, third arrow = lane
// down/right/up are the 3 choices
// left is saved for block later

function player_input_create()
{
    inputSequence = [];
    inputCount = 0;
    inputTimer = 0;

    // clears combo if player waits too long
    inputResetTime = room_speed * 3;

    // cooldown after casting so player cant spam spells
    // same as enemy cooldown
    playerCastCooldownTime = room_speed * 1;
    playerCastCooldownTimer = 0;

    // input feedback for the bottom arrows
    inputVisualTime = 24;
    inputVisualTimer = [0, 0, 0];

    // wait after casting so we dont insta clear arrows
    inputVisualClearTimer = 0;
    inputVisualClearDelay = room_speed * 0.5;

    // quick lookups so we dont need huge if chains everywhere
    spellPowerValues = [SpellPower.QUICK, SpellPower.MEDIUM, SpellPower.STRONG];
    spellElementValues = [SpellElement.FIRE, SpellElement.WATER, SpellElement.AIR];
    spellLaneValues = [SpellLane.LOW, SpellLane.MIDDLE, SpellLane.HIGH];

    spellPowerText = ["Quick", "Medium", "Strong"];
    spellElementText = ["Fire", "Water", "Air"];
    spellLaneText = ["Low", "Middle", "High"];

    global.inputVisualArrows = [-1, -1, -1];
    global.inputVisualText = ["_", "_", "_"];
    global.inputText = "";
}

function player_input_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    inputTimer += 1;

    // tick down spell cooldown
    if (playerCastCooldownTimer > 0)
    {
        playerCastCooldownTimer -= 1;
    }

    // clears the bottom arrow UI after casting
    if (inputVisualClearTimer > 0)
    {
        inputVisualClearTimer -= 1;

        if (inputVisualClearTimer <= 0)
        {
            player_input_clear_visuals();
        }
    }

    // tick down the arrow timers
    for (var i = 0; i < 3; i += 1)
    {
        if (inputVisualTimer[i] > 0)
        {
            inputVisualTimer[i] -= 1;
        }
    }

    if (inputCount > 0 && inputTimer > inputResetTime)
    {
        player_input_clear();
        player_input_clear_visuals();
    }

    // dont accept new spell inputs while cooling down
    if (playerCastCooldownTimer > 0)
    {
        return;
    }

    // input 1 = power, input 2 = element, input 3 = lane
    // down/right/up are the 3 choices each time
    if (keyboard_check_pressed(vk_down))
    {
        player_input_add(0);
    }

    if (keyboard_check_pressed(vk_right))
    {
        player_input_add(1);
    }

    if (keyboard_check_pressed(vk_up))
    {
        player_input_add(2);
    }

    // left arrow is intentionally unused
    // saving it for block later
}

function player_input_add(_input)
{
    inputVisualClearTimer = 0;

    var _slot = inputCount;

    inputSequence[inputCount] = _input;
    inputCount += 1;
    inputTimer = 0;

    // store the pressed arrow for the bottom UI
    if (_slot >= 0 && _slot < 3)
    {
        global.inputVisualArrows[_slot] = _input;
        inputVisualTimer[_slot] = inputVisualTime;

        if (_slot == 0)
        {
            global.inputVisualText[_slot] = player_input_strength_text(_input);
        }
        else if (_slot == 1)
        {
            global.inputVisualText[_slot] = player_input_element_text(_input);
        }
        else
        {
            global.inputVisualText[_slot] = player_input_lane_text(_input);
        }
    }

    global.inputText = player_input_sequence_to_text();

    if (inputCount >= 3)
    {
        player_input_try_cast();
    }
}

function player_input_clear()
{
    inputSequence = [];
    inputCount = 0;
    inputTimer = 0;

    global.inputText = "";
}

function player_input_clear_visuals()
{
    global.inputVisualArrows = [-1, -1, -1];
    global.inputVisualText = ["_", "_", "_"];
    inputVisualTimer = [0, 0, 0];
}

function player_input_try_cast()
{
    if (inputCount < 3)
    {
        return;
    }

    if (playerCastCooldownTimer > 0)
    {
        player_input_clear();
        player_input_clear_visuals();
        return;
    }

    var _spellInfo = player_input_to_spell_info();

    player_cast_spell(_spellInfo);

    global.debugText = "Player cast " + spell_info_to_text(_spellInfo);

    // start cooldown after casting
    playerCastCooldownTimer = playerCastCooldownTime;

    // clear combo straight away
    player_input_clear();

    // keep the arrows visible for half a second
    inputVisualClearTimer = inputVisualClearDelay;
}

function player_input_to_spell_info()
{
    var _powerInput = inputSequence[0];
    var _elementInput = inputSequence[1];
    var _laneInput = inputSequence[2];

    var _spellPower = spellPowerValues[_powerInput];
    var _spellElement = spellElementValues[_elementInput];
    var _spellLane = spellLaneValues[_laneInput];

    return new SpellData(_spellPower, _spellElement, _spellLane);
}

function player_input_sequence_to_text()
{
    var _text = "";

    // show strength after first key
    if (inputCount >= 1)
    {
        _text += player_input_strength_text(inputSequence[0]);
    }
    else
    {
        _text += "_";
    }

    _text += " ";

    // show element after second key
    if (inputCount >= 2)
    {
        _text += player_input_element_text(inputSequence[1]);
    }
    else
    {
        _text += "_";
    }

    _text += " ";

    // show lane after third key
    if (inputCount >= 3)
    {
        _text += player_input_lane_text(inputSequence[2]);
    }
    else
    {
        _text += "_";
    }

    return _text;
}

function player_input_strength_text(_input)
{
    return spellPowerText[_input];
}

function player_input_element_text(_input)
{
    return spellElementText[_input];
}

function player_input_lane_text(_input)
{
    return spellLaneText[_input];
}