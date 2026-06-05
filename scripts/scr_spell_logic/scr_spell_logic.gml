// script to handle all of our spell logic

function spell_create()
{
    // who created the spell
    owner = noone;

    // SpellData struct
    data = undefined;

    spellPower = SpellPower.QUICK;
    spellElement = SpellElement.FIRE;

    powerValue = 1;

    // 1 means move right, -1 means move left
    moveDirection = 0;

    moveSpeed = 0;
    damage = 0;
    radius = 10;

    // Spells should not do ANYTHING until properly spawned
    isInitialized = false;

    // animation
    image_index = 0;
    image_speed = 0.25;

    // sprites
    sprFire = asset_get_index("spr_spell_fire");
    sprWater = asset_get_index("spr_spell_water");
    sprAir = asset_get_index("spr_spell_air");
}

function spell_spawn(_owner, _spellInfo, _x, _y, _direction)
{
    var _spell = instance_create_layer(_x, _y, global.config.instanceLayer, obj_spell);

    with (_spell)
    {
        owner = _owner;
        data = _spellInfo;

        spellPower = _spellInfo.spellPower;
        spellElement = _spellInfo.spellElement;

        powerValue = _spellInfo.powerValue;

        moveDirection = _direction;

        x = _x;
        y = _y;

        // pick the right spell sprite
        sprite_index = spell_get_sprite();
        image_index = 0;
        image_speed = 0.25;

        spell_refresh_stats_from_power(id);

        isInitialized = true;
    }

    return _spell;
}

function spell_step()
{
    // Do nothing while paused
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // If the spell has not been set up yet ignore it
    if (!isInitialized)
    {
        return;
    }

    x += moveSpeed * moveDirection;

    spell_check_spell_collision();

    if (instance_exists(id))
    {
        spell_check_wizard_hit();
    }

    if (instance_exists(id))
    {
        if (x < -80 || x > room_width + 80)
        {
            instance_destroy();
        }
    }
}

function spell_draw()
{
    // dont draw inactive spells
    if (!isInitialized)
    {
        return;
    }

    var _spr = spell_get_sprite();

    if (_spr != -1)
    {
        var _scale = spell_get_draw_scale();

        // flips enemy spells after the final scale is chosen
        var _xScale = _scale * moveDirection;

        draw_sprite_ext(_spr, image_index, x, y, _xScale, _scale, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(spell_get_colour());
        draw_circle(x, y, radius, false);
    }

    // uncomment while tuning spell collision
    // spell_draw_debug_hitbox();
}

function spell_get_draw_scale()
{
    var _scale = 1;

    if (powerValue == 2)
    {
        _scale = 1.25;
    }
    else if (powerValue >= 3)
    {
        _scale = 1.5;
    }

    return _scale;
}

function spell_get_sprite()
{
    if (spellElement == SpellElement.FIRE)
    {
        return sprFire;
    }

    if (spellElement == SpellElement.WATER)
    {
        return sprWater;
    }

    return sprAir;
}

function spell_get_colour()
{
    if (spellElement == SpellElement.FIRE)
    {
        return make_colour_rgb(255, 90, 30);
    }

    if (spellElement == SpellElement.WATER)
    {
        return make_colour_rgb(60, 150, 255);
    }

    return make_colour_rgb(220, 240, 255);
}

function spell_get_instance_hit_radius(_spellInst)
{
    if (!instance_exists(_spellInst))
    {
        return 8;
    }

    var _spr = -1;

    if (_spellInst.spellElement == SpellElement.FIRE)
    {
        _spr = _spellInst.sprFire;
    }
    else if (_spellInst.spellElement == SpellElement.WATER)
    {
        _spr = _spellInst.sprWater;
    }
    else
    {
        _spr = _spellInst.sprAir;
    }

    if (_spr == -1)
    {
        return _spellInst.radius;
    }

    var _bboxW = sprite_get_bbox_right(_spr) - sprite_get_bbox_left(_spr);
    var _bboxH = sprite_get_bbox_bottom(_spr) - sprite_get_bbox_top(_spr);

    var _largest = _bboxW;

    if (_bboxH > _largest)
    {
        _largest = _bboxH;
    }

    var _scale = 1;

    if (_spellInst.powerValue == 2)
    {
        _scale = 1.25;
    }
    else if (_spellInst.powerValue >= 3)
    {
        _scale = 1.5;
    }

    return (_largest * _scale) * 0.5;
}

function spell_get_instance_bbox(_inst, _side)
{
    if (!instance_exists(_inst))
    {
        return 0;
    }

    var _drawY = _inst.y;

    // player jump moves the drawn sprite and hitbox up
    if (variable_instance_exists(_inst, "jumpOffset"))
    {
        _drawY += _inst.jumpOffset;
    }

    var _drawSprite = -1;

    if (!variable_instance_exists(_inst, "drawSprite"))
    {
        _drawSprite = -1;
    }
    else
    {
        _drawSprite = _inst.drawSprite;
    }

    if (_drawSprite == -1)
    {
        if (_side == 0) return _inst.x - 32;
        if (_side == 1) return _inst.x + 32;
        if (_side == 2) return _drawY - 48;
        return _drawY + 48;
    }

    var _scale = 3 * depth_scale_from_y(_inst.y);

    if (_side == 0) return _inst.x + ((sprite_get_bbox_left(_drawSprite) - sprite_get_xoffset(_drawSprite)) * _scale);
    if (_side == 1) return _inst.x + ((sprite_get_bbox_right(_drawSprite) - sprite_get_xoffset(_drawSprite)) * _scale);
    if (_side == 2) return _drawY + ((sprite_get_bbox_top(_drawSprite) - sprite_get_yoffset(_drawSprite)) * _scale);
    return _drawY + ((sprite_get_bbox_bottom(_drawSprite) - sprite_get_yoffset(_drawSprite)) * _scale);
}

function spell_get_instance_bbox_left(_inst)
{
    return spell_get_instance_bbox(_inst, 0);
}

function spell_get_instance_bbox_right(_inst)
{
    return spell_get_instance_bbox(_inst, 1);
}

function spell_get_instance_bbox_top(_inst)
{
    return spell_get_instance_bbox(_inst, 2);
}

function spell_get_instance_bbox_bottom(_inst)
{
    return spell_get_instance_bbox(_inst, 3);
}

function spell_check_wizard_hit()
{
    if (!instance_exists(owner))
    {
        instance_destroy();
        return;
    }

    var _target = noone;

    if (owner == global.player)
    {
        _target = global.enemy;
    }
    else
    {
        _target = global.player;
    }

    if (!instance_exists(_target))
    {
        return;
    }

    var _left = spell_get_instance_bbox_left(_target);
    var _right = spell_get_instance_bbox_right(_target);
    var _top = spell_get_instance_bbox_top(_target);
    var _bottom = spell_get_instance_bbox_bottom(_target);

    var _hitRadius = spell_get_instance_hit_radius(id);

    if (spell_rect_circle_overlap(_left, _top, _right, _bottom, x, y, _hitRadius))
    {
        if (_target == global.player)
        {
            with (_target)
            {
                player_take_damage(other.damage);
            }
        }
        else
        {
            with (_target)
            {
                enemy_take_damage(other.damage);
            }
        }

        instance_destroy();
    }
}

function spell_check_spell_collision()
{
    var _self = id;

    with (obj_spell)
    {
        if (id != _self)
        {
            if (instance_exists(_self))
            {
                if (isInitialized && _self.isInitialized)
                {
                    if (owner != _self.owner)
                    {
                        var _dist = point_distance(x, y, _self.x, _self.y);
                        var _selfRadius = spell_get_instance_hit_radius(_self);
                        var _otherRadius = spell_get_instance_hit_radius(id);

                        if (_dist <= _selfRadius + _otherRadius)
                        {
                            var _result = spell_resolve_collision(_self, id);

                            if (_result == 0)
                            {
                                // both spells cancel
                                with (_self)
                                {
                                    instance_destroy();
                                }

                                instance_destroy();
                            }
                            else if (_result == 1)
                            {
                                // first spell wins, this spell loses
                                instance_destroy();
                            }
                            else if (_result == 2)
                            {
                                // this spell wins, first spell loses
                                with (_self)
                                {
                                    instance_destroy();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

function spell_resolve_collision(_spellA, _spellB)
{
    if (!instance_exists(_spellA) || !instance_exists(_spellB))
    {
        return -1;
    }

    var _powerA = _spellA.powerValue;
    var _powerB = _spellB.powerValue;

    var _elementA = _spellA.spellElement;
    var _elementB = _spellB.spellElement;

    // same power and same element means both disappear
    if (_powerA == _powerB && _elementA == _elementB)
    {
        global.debugText = "Spells cancelled";
        return 0;
    }

    // same power means element decides
    if (_powerA == _powerB)
    {
        var _elementResult = spell_compare_elements(_elementA, _elementB);

        if (_elementResult == 1)
        {
            global.debugText = "Element clash won";
            return 1;
        }

        if (_elementResult == -1)
        {
            global.debugText = "Element clash won";
            return 2;
        }

        return 0;
    }

    // different power but same element means stronger spell wins cleanly
    if (_elementA == _elementB)
    {
        if (_powerA > _powerB)
        {
            global.debugText = "Power clash won";
            return 1;
        }

        global.debugText = "Power clash won";
        return 2;
    }

    // different power and different element means stronger wins but loses power
    if (_powerA > _powerB)
    {
        spell_reduce_power_after_clash(_spellA, _powerB);
        global.debugText = "Spell power reduced";
        return 1;
    }

    spell_reduce_power_after_clash(_spellB, _powerA);
    global.debugText = "Spell power reduced";
    return 2;
}

function spell_compare_elements(_elementA, _elementB)
{
    if (_elementA == _elementB)
    {
        return 0;
    }

    // fire beats air
    if (_elementA == SpellElement.FIRE && _elementB == SpellElement.AIR)
    {
        return 1;
    }

    // air beats water
    if (_elementA == SpellElement.AIR && _elementB == SpellElement.WATER)
    {
        return 1;
    }

    // water beats fire
    if (_elementA == SpellElement.WATER && _elementB == SpellElement.FIRE)
    {
        return 1;
    }

    return -1;
}

function spell_reduce_power_after_clash(_spell, _amount)
{
    if (!instance_exists(_spell))
    {
        return;
    }

    with (_spell)
    {
        powerValue -= _amount;

        if (powerValue <= 0)
        {
            instance_destroy();
        }
        else
        {
            spellPower = spell_value_to_power(powerValue);
            spell_refresh_stats_from_power(id);
        }
    }
}

function spell_refresh_stats_from_power(_spell)
{
    if (!instance_exists(_spell))
    {
        return;
    }

    with (_spell)
    {
        var _stats = spell_get_stats_from_power_value(powerValue);

        moveSpeed = _stats.speed;
        damage = _stats.damage;

        // fallback radius, real hit radius comes from sprite bbox when possible
        radius = _stats.radius;
    }
}

function spell_rect_circle_overlap(_left, _top, _right, _bottom, _cx, _cy, _radius)
{
    var _closestX = clamp(_cx, _left, _right);
    var _closestY = clamp(_cy, _top, _bottom);

    return point_distance(_cx, _cy, _closestX, _closestY) <= _radius;
}

function spell_draw_debug_hitbox()
{
    draw_set_alpha(0.45);
    draw_set_colour(c_yellow);
    draw_circle(x, y, spell_get_instance_hit_radius(id), true);
    draw_set_alpha(1);
}

function spell_info_to_text(_spellInfo)
{
    return spell_power_to_text(_spellInfo.spellPower)
        + " "
        + spell_element_to_text(_spellInfo.spellElement);
}

function spell_power_to_text(_spellPower)
{
    if (_spellPower == SpellPower.QUICK)
    {
        return "Quick";
    }

    if (_spellPower == SpellPower.MEDIUM)
    {
        return "Medium";
    }

    return "Strong";
}

function spell_element_to_text(_spellElement)
{
    if (_spellElement == SpellElement.FIRE)
    {
        return "Fire";
    }

    if (_spellElement == SpellElement.WATER)
    {
        return "Water";
    }

    return "Air";
}

function spell_lane_to_text(_spellLane)
{
    if (_spellLane == SpellLane.LOW)
    {
        return "Low";
    }

    if (_spellLane == SpellLane.MIDDLE)
    {
        return "Middle";
    }

    return "High";
}
