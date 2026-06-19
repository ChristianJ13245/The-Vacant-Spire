// charge-based spell input
// Keyboard: A/D cycle element, K charges, releasing K casts
// Mouse: scroll wheel cycles element, left click charges, releasing left click casts
// W/S movement and space jump live in player logic

function player_input_create()
{
    // current spell setup
    // player changes this before charging
    selectedElement = SpellElement.FIRE;

    // cast key
    // change this one line if the key needs to move again
    castKey = ord("K");

    // charge state
    isCharging = false;
    chargeFrames = 0;

    // charge timings
    // short = quick, medium = medium, long = strong
    mediumChargeFrames = room_speed * 0.35;
    strongChargeFrames = room_speed * 1.1;
    maxChargeFrames = room_speed * 1.4;

    // cooldown after casting so player cant spam spells
    // can tune this after testing
    playerCastCooldownTime = room_speed * 0.45;
    playerCastCooldownTimer = 0;

    global.inputText = player_input_status_text();
}

function player_input_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // tick down spell cooldown
    if (playerCastCooldownTimer > 0)
    {
        playerCastCooldownTimer -= 1;
    }

    var _useMouse = player_input_uses_mouse_scheme();
    var _chargePressed = keyboard_check_pressed(castKey);
    var _chargeHeld = keyboard_check(castKey);
    var _chargeReleased = keyboard_check_released(castKey);

    // element can change at any time, even while holding a charged spell
    if (_useMouse)
    {
        if (mouse_wheel_up())
        {
            player_input_cycle_element(-1);
        }

        if (mouse_wheel_down())
        {
            player_input_cycle_element(1);
        }
    }
    else
    {
        if (keyboard_check_pressed(ord("A")))
        {
            player_input_cycle_element(-1);
        }

        if (keyboard_check_pressed(ord("D")))
        {
            player_input_cycle_element(1);
        }
    }

    if (_useMouse)
    {
        _chargePressed = mouse_check_button_pressed(mb_left);
        _chargeHeld = mouse_check_button(mb_left);
        _chargeReleased = mouse_check_button_released(mb_left);
    }

    // start charge
    if (_chargePressed)
    {
        player_input_start_charge();
    }

    // if the cast input stayed held, start again once mana is full
    if (!isCharging && _chargeHeld && player_input_can_auto_charge())
    {
        player_input_start_charge();
    }

    // keep charging while the cast input is held
    if (isCharging && _chargeHeld)
    {
        player_input_update_charge();
    }

    // release to cast
    if (isCharging && _chargeReleased)
    {
        player_input_release_charge();
    }

    global.inputText = player_input_status_text();
}

function player_input_uses_mouse_scheme()
{
    return variable_global_exists("controlScheme") && global.controlScheme == "mouse";
}

function player_input_start_charge()
{
    // dont start a new charge during cooldown
    if (playerCastCooldownTimer > 0)
    {
        return;
    }

    isCharging = true;
    chargeFrames = 0;
}

function player_input_can_auto_charge()
{
    if (playerCastCooldownTimer > 0)
    {
        return false;
    }

    return currentMana >= maxMana;
}

function player_input_update_charge()
{
    chargeFrames += 1;

    // caps charge so it doesnt climb forever
    if (chargeFrames > maxChargeFrames)
    {
        chargeFrames = maxChargeFrames;
    }
}

function player_input_release_charge()
{
    if (playerCastCooldownTimer > 0)
    {
        isCharging = false;
        chargeFrames = 0;
        return;
    }

    var _spellPower = player_input_power_from_charge();
    var _spellInfo = new SpellData(_spellPower, selectedElement);

    var _didCast = player_cast_spell(_spellInfo);

    isCharging = false;
    chargeFrames = 0;

    // small input cooldown only if a spell actually fired
    if (_didCast)
    {
        playerCastCooldownTimer = playerCastCooldownTime;
    }
}

function player_input_power_from_charge()
{
    // tap / tiny charge
    if (chargeFrames < mediumChargeFrames)
    {
        return SpellPower.QUICK;
    }

    // decent charge
    if (chargeFrames < strongChargeFrames)
    {
        return SpellPower.MEDIUM;
    }

    // full charge
    return SpellPower.STRONG;
}

function player_input_cycle_element(_direction)
{
    selectedElement += _direction;

    // wrap around backwards
    if (selectedElement < SpellElement.FIRE)
    {
        selectedElement = SpellElement.AIR;
    }

    // wrap around forwards
    if (selectedElement > SpellElement.AIR)
    {
        selectedElement = SpellElement.FIRE;
    }
}

function player_input_charge_ratio()
{
    if (maxChargeFrames <= 0)
    {
        return 0;
    }

    return clamp(chargeFrames / maxChargeFrames, 0, 1);
}

function player_input_status_text()
{
    var _powerText = "Ready";

    if (playerCastCooldownTimer > 0)
    {
        _powerText = "Cooldown";
    }
    else if (isCharging)
    {
        _powerText = spell_power_to_text(player_input_power_from_charge());
    }

    return spell_element_to_text(selectedElement)
        + " | "
        + _powerText;
}
