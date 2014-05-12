##Welcome to the official FF2 repository!
**LATEST VERSION**: [1.10.0](https://forums.alliedmods.net/showpost.php?p=2054933&postcount=1)

[![Build Status](http://198.27.69.149/jenkins/buildStatus/icon?job=FF2-Official)](http://198.27.69.149/jenkins/job/FF2-Official/) - Currently Disabled

FF2-Official features multiple branches, which are described below:
* All development work towards the next major version of FF2 is done in the [development](https://github.com/50DKP/FF2-Official/tree/development) branch.
* The [stable](https://github.com/50DKP/FF2-Official/tree/stable) branch contains bugfixes for the most recent version of FF2.
* Once changes are considered ready for release, they are merged into the [master](https://github.com/50DKP/FF2-Official/tree/master) branch.  This branch will always contain a released version of FF2.
* [Powerlord's](https://github.com/powerlord/) rewrite of FF2 is housed in the [rewrite](https://github.com/50DKP/FF2-Official/tree/rewrite) branch.  These changes are slowly being assimilated into the [experimental](https://github.com/50DKP/FF2-Official/tree/experimental) branch.
* Finally, the [experimental](https://github.com/50DKP/FF2-Official/tree/experimental) branch contains experimental work being done towards the next iteration of FF2.
* The default branch is changed to reflect where the most work is currently being done.

###Include File Changes
***
Some third-party include files were modified in order to make FF2 work properly with or without the plugin that the include file belonged to.
It is highly recommended that you also make these changes when compiling FF2.

`smac.inc`:
* Remove: 
```sourcepawn
MarkNativeAsOptional("SMAC_CheatDetected");
```

`rtd.inc`:
* Add: 
```sourcepawn
#if defined REQUIRE_PLUGIN
required = 1
#else
required = 0
#endif
```
inside `public SharedPlugin:__pl_rtd = `

###Formatting
***
If you wish to make a pull request, the following formatting rules should be adhered to:

* Braces on new line
* No spaces between parentheses or most operators (=, ==, *, |, &, etc)
	* **Exception**: One space between &&, ||, ;, and ,
	* *Note*: & and | formatting rules are currently not enforced
* Tabs, not spaces
* No tabs on newline
* No whitespace after a line
* Bracket all conditional statements, even if it is not required (one-line if statements, for example)
* Variable names should be camel-cased (markdownIsStupid)
* Method names should be capitalized normally (MarkNativeAsOptional)

Example:

```sourcepawn
if(markdownIsStupid)
{
	if(ubuntuIsAmazing)
	{
		while(!someOtherBoolean)
		{
			for(new i=0; i<=someOtherNumber; i+=3)
			{
				if(i==someNumber && moreVariableNames!=42)
				{
					someOtherBoolean=true;
				}
			}
		}
	}

	someBitWiseThing[someNumber]=someBitWiseThing[someNumber]|coolBitWiseVariable;
	return;
}
```
