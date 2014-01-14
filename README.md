##Welcome to the official FF2 repository!
**LATEST VERSION**: [1.0.8](https://forums.alliedmods.net/showpost.php?p=2054933&postcount=1)

###Compiling FF2
***
This tutorial assumes you have TF2 installed. and place it anywhere you want, preferably in a `/tf/addons/sourcemod/` configuration.

####Setup Git
1. Download and install Git [here](http://git-scm.com/download/).
	* It is strongly recommended to allow Git to handle `.sh` extensions if installing on Windows.
2. *Optional*: Download and install a Git GUI client, such as Github for Windows/Mac, SmartGitHg, TortoiseGit, etc.  A nice list is available [here](http://git-scm.com/downloads/guis).

####Compile FF2
1. Open up your command line.
2. Navigate to your TF2 server's location, eg `C:\Servers\TF2\FF2-Official\tf` by executing `cd [folder location]`.  This location is hereby referred to as `ff2dev`.
3. Execute `git clone https://github.com/50DKP/FF2-Official.git`.
4. Right now, you should have a folder structure that looks like:

***
	ff2dev
	\-tf
		\-addons
			\-sourcemod
				\-Misc. Sourcemod files (should have `scripting` and `plugins`)
***

####Installing Sourcemod
1. Download [Sourcemod](http://www.sourcemod.net/downloads.php).
2. Extract it to `ff2dev` so that all the directories match up.

####Compile FF2
1. Navigate to `tf/addons/sourcemod/scripting` in the command prompt.
2. Execute `compile.sh freak_fortress_2.sp`.
	* **NOTE**: This will only work on Windows if you allowed Git to make `.sh` bash files executable.
3. The compiled file will be in `scripting/compiled`, which you can then move to `/plugins/`.

####Updating Your Repository
In order to get the most up-to-date builds, you'll have to periodically update your local repository.

1. Open up your command line.
2. Navigate to `ff2dev` in the console.
3. Make sure you have not made any changes to the local repository, or else there might be issues with Git.
	* If you have, try reverting them to the status that they were when you last updated your repository.
4. Execute `git pull master`.  This pulls all commits from the official repository that do not yet exist on your local repository and updates it.

###Label Information
***
* `bug-critical` denotes severe game-impeding bugs that generally do not have a workaround.
	* *Examples*: Server crashes, unplayable bosses, etc.
* `bug-major` denotes game-impeding bugs that generally have a workaround and/or can be easily avoided.
	* *Examples*: Suicide/weapon-related bugs, etc.
* `bug-minor` denotes bugs that generally are visual-only and do not seriously affect gameplay.
	* *Examples*: No HUD, missing text, etc.
* `feedback-required` denotes issues that require feedback from others.
	* *Examples*: Suggestions, etc.