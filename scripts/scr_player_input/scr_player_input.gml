// charge-based spell input
// left/right cycle element
// up/down changes lane
// space charges, releasing space casts

function player_input_create()
{
    // current spell setup
    // player changes these before charging
    selectedElement = SpellElement.FIRE;
    selectedLane = SpellLane.MIDDLE;

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

    // dont change element/lane while charging
    // keeps the spell choice locked once space is held
    if (!isCharging)
    {
        // cycle element
        if (keyboard_check_pressed(vk_left))
        {
            player_input_cycle_element(-1);
        }

        if (keyboard_check_pressed(vk_right))
        {
            player_input_cycle_element(1);
        }

        // change lane
        if (keyboard_check_pressed(vk_up))
        {
            player_input_move_lane(1);
        }

        if (keyboard_check_pressed(vk_down))
        {
            player_input_move_lane(-1);
        }
    }

    // start charge
    if (keyboard_check_pressed(vk_space))
    {
        player_input_start_charge();
    }

    // keep charging while space is held
    if (isCharging && keyboard_check(vk_space))
    {
        player_input_update_charge();
    }

    // release to cast
    if (isCharging && keyboard_check_released(vk_space))
    {
        player_input_release_charge();
    }

    global.inputText = player_input_status_text();
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
    // if cooldown somehow starts, cancel safely
    if (playerCastCooldownTimer > 0)
    {
        isCharging = false;
        chargeFrames = 0;
        return;
    }

    var _spellPower = player_input_power_from_charge();
    var _spellInfo = new SpellData(_spellPower, selectedElement, selectedLane);

	// cast function handles mana checking
	player_cast_spell(_spellInfo);

	isCharging = false;
	chargeFrames = 0;

	// small input cooldown either way so space cant machine-gun
	playerCastCooldownTimer = playerCastCooldownTime;
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

function player_input_move_lane(_direction)
{
    selectedLane += _direction;

    // enum order is low = 0, middle = 1, high = 2
    if (selectedLane < SpellLane.LOW)
    {
        selectedLane = SpellLane.LOW;
    }

    if (selectedLane > SpellLane.HIGH)
    {
        selectedLane = SpellLane.HIGH;
    }
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
        + spell_lane_to_text(selectedLane)
        + " | "
        + _powerText;
}