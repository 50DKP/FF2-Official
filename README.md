##Welcome to the official FF2 repository!
**LATEST VERSION**: [1.9.0](https://forums.alliedmods.net/showpost.php?p=2054933&postcount=1)

[![Build Status](http://198.27.69.149/jenkins/buildStatus/icon?job=FF2-Official)](http://198.27.69.149/jenkins/job/FF2-Official/)

FF2-Official features multiple branches, which are described below:
* All development work towards the next major version of FF2 is done in the [development](https://github.com/50DKP/FF2-Official/tree/development) branch.
* The [stable](https://github.com/50DKP/FF2-Official/tree/stable) branch contains bugfixes for the most recent version of FF2.
* Once changes are considered ready for release, they are merged into the [master](https://github.com/50DKP/FF2-Official/tree/master) branch.  This branch will always contain a released version of FF2.
* [Powerlord's](https://github.com/powerlord/) rewrite of FF2 is housed in the [rewrite](https://github.com/50DKP/FF2-Official/tree/rewrite) branch.  These changes are slowly being assimilated into the [experimental](https://github.com/50DKP/FF2-Official/tree/experimental) branch.
* Finally, the [experimental](https://github.com/50DKP/FF2-Official/tree/experimental) branch contains experimental work being done towards the next iteration of FF2.
* The default branch is changed to reflect where the most work is currently being done.

###Compiling FF2
***
This tutorial assumes you have TF2 installed.

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
* `bug-minor` denotes bugs that are generally visual-only and/or do not seriously affect gameplay.  This may also include bugs that are not always reproducible.
	* *Examples*: No HUD, missing text, etc.
* `feedback-required` denotes issues that require feedback from others.
	* *Examples*: Suggestions, etc.