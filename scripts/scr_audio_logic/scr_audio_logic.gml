// simple audio manager
// swaps between menu music and battle music

function audio_manager_create()
{
    // music assets
    menuMusic = snd_menu_music;
    battleMusic = snd_battle_music;

    // volumes
    menuVolume = 0.65;
    battleVolume = 0.4;

    // fade values
    currentVolume = 0;
    targetVolume = menuVolume;
    volumeFadeSpeed = 0.025;

    // current music info
    currentMusic = -1;
    currentMusicId = -1;
    targetMusic = -1;

    audio_pick_target_music();
    audio_start_music(targetMusic);
}

function audio_manager_step()
{
    audio_pick_target_music();

    if (targetMusic != currentMusic)
    {
        audio_switch_music(targetMusic);
    }

    audio_fade_music_volume();
}

function audio_pick_target_music()
{
    if (global.gameState == GameState.MENU
    || global.gameState == GameState.HELP)
    {
        targetMusic = menuMusic;
        targetVolume = menuVolume;
        return;
    }

    targetMusic = battleMusic;
    targetVolume = battleVolume;
}

function audio_start_music(_music)
{
    if (_music == -1)
    {
        return;
    }

    currentMusic = _music;
    currentVolume = 0;

    currentMusicId = audio_play_sound(currentMusic, 10, true);
    audio_sound_gain(currentMusicId, currentVolume, 0);
}

function audio_switch_music(_music)
{
    if (currentMusicId != -1)
    {
        audio_stop_sound(currentMusicId);
    }

    currentMusicId = -1;
    currentMusic = -1;

    audio_start_music(_music);
}

function audio_fade_music_volume()
{
    if (currentMusicId == -1)
    {
        return;
    }

    if (!audio_is_playing(currentMusicId))
    {
        return;
    }

    if (currentVolume < targetVolume)
    {
        currentVolume += volumeFadeSpeed;

        if (currentVolume > targetVolume)
        {
            currentVolume = targetVolume;
        }
    }
    else if (currentVolume > targetVolume)
    {
        currentVolume -= volumeFadeSpeed;

        if (currentVolume < targetVolume)
        {
            currentVolume = targetVolume;
        }
    }

    audio_sound_gain(currentMusicId, currentVolume, 0);
}