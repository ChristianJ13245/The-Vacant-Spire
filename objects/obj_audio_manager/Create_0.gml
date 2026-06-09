/// @description Audio manager create event

if (instance_number(obj_audio_manager) > 1)
{
    instance_destroy();
    exit;
}

audio_manager_create();













