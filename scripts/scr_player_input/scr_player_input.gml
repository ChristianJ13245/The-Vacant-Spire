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

    global.inputText = "";
}

function player_input_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    inputTimer += 1;

    if (inputCount > 0 && inputTimer > inputResetTime)
    {
        player_input_clear();
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
    inputSequence[inputCount] = _input;
    inputCount += 1;
    inputTimer = 0;

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

function player_input_try_cast()
{
    if (inputCount < 3)
    {
        return;
    }

    var _spellInfo = player_input_to_spell_info();

    player_cast_spell(_spellInfo);

    global.debugText = "Player cast " + spell_info_to_text(_spellInfo);

    player_input_clear();
}

function player_input_to_spell_info()
{
    var _powerInput = inputSequence[0];
    var _elementInput = inputSequence[1];
    var _laneInput = inputSequence[2];

    var _spellPower = SpellPower.QUICK;
    var _spellElement = SpellElement.FIRE;
    var _spellLane = SpellLane.LOW;

    // first input picks strength
    if (_powerInput == 0)
    {
        _spellPower = SpellPower.QUICK;
    }
    else if (_powerInput == 1)
    {
        _spellPower = SpellPower.MEDIUM;
    }
    else
    {
        _spellPower = SpellPower.STRONG;
    }

    // second input picks element
    if (_elementInput == 0)
    {
        _spellElement = SpellElement.FIRE;
    }
    else if (_elementInput == 1)
    {
        _spellElement = SpellElement.WATER;
    }
    else
    {
        _spellElement = SpellElement.AIR;
    }

    // third input picks lane
    if (_laneInput == 0)
    {
        _spellLane = SpellLane.LOW;
    }
    else if (_laneInput == 1)
    {
        _spellLane = SpellLane.MIDDLE;
    }
    else
    {
        _spellLane = SpellLane.HIGH;
    }

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
    if (_input == 0)
    {
        return "Quick";
    }

    if (_input == 1)
    {
        return "Medium";
    }

    return "Strong";
}

function player_input_element_text(_input)
{
    if (_input == 0)
    {
        return "Fire";
    }

    if (_input == 1)
    {
        return "Water";
    }

    return "Air";
}

function player_input_lane_text(_input)
{
    if (_input == 0)
    {
        return "Low";
    }

    if (_input == 1)
    {
        return "Middle";
    }

    return "High";
}