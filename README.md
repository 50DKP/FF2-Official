## Welcome to the official FF2 repository! [![Build Status](https://travis-ci.org/50DKP/FF2-Official.svg?branch=stable)](https://travis-ci.org/50DKP/FF2-Official)

Want the latest version?  Check out the [Releases](https://github.com/50DKP/FF2-Official/releases) page.  You can also check out the [forums](https://forums.alliedmods.net/forumdisplay.php?f=154) to learn more.  Brought to you by [50DKP](http://www.50dkp.com).

### Include File Changes
***
Some third-party include files were modified in order to make FF2 work properly with or without the plugin that the include file belonged to.
It is highly recommended that you also make these changes when compiling FF2.

`smac.inc`:
* Remove:
```sourcepawn
MarkNativeAsOptional("SMAC_CheatDetected");
```


### Formatting
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
* New syntax should be used 

Example:

```sourcepawn
if(markdownIsStupid)
{
	if(ubuntuIsAmazing)
	{
		while(!someOtherBoolean)
		{
			for(int i=0; i<=someOtherNumber; i+=3)
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
