function loadAnimations()
{
    /**
    * hi hi hello gabi here
    * this is a example file to show how characters work on the engine
    ==========================================================================================
    * first off, as long as your sparrow/packer atlas file and image file is in the folder containing this script
    * you should be good to go, furthermore, they need to be named with your character's internal name
    * for example, if the character folder name is `bf`, then his internal name is `bf`, and so, files need to be named `bf.png` and `bf.(ext)` (ext being either xml, json or txt);
    * along with this script, which should be named `config.hx`, and of course the character icon, which should be named `icon.png`
    **/

    /* ===== ANIMATION PREFIXES ===== */

    // here we set up the animation prefixes for later use
    addByPrefix('idle', 'BF idle dance', 24, false);
    addByPrefix('singUP', 'BF NOTE UP0', 24, false);
    addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
    addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
    addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
    addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
    addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
    addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
    addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
    addByPrefix('hey', 'BF HEY', 24, false);
    addByPrefix('scared', 'BF idle shaking', 24);

    // this is not actually for boyfriend, but just an example on how adding indice animations work
    addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 24, false);
    addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], 24, false);

    // play idle
    playAnim('idle');

    // add offsets if we need any for the prefixes (usually yes, we do)
    addOffset('hey', -3);

    /**
    * this is all optional, but here, we set up things like character health bar colors, camera offsets,
    * character scales, custom icons, and whether the character is a quick dancer (think gf, spooky kids) or not!
    **/
    setBarColor([49,176,209]); // uses an rgb format
    setCameraPositions(0, -50); //x, y
    setScale(1, 1); // scale x, scale y
    quickDancer(false);

     /**
        *   NOTICE: icons always search for the character's internal name
        *   so make sure to create a dedicated folder for your custom icons!
        *   example: `characters/customIcons/beta-bf/icon.png` - it will get the `icon.png` file inside this folder.
    **/
    setIcon('exampleChar/customIcons/bf'); // optional, but if you ever wanna set a custom icon, there you have it!

    // game over screen set up
    // from left to right, character that has the death animations, sound effect that plays when dying, game over song, jingle that plays on retry, and song bpm!
    setDeathChar('bf-dead', 'fnf_loss_sfx', 'gameOver', 'gameOverEnd', 100);
}