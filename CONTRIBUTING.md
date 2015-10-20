# Contributing
First of all, thanks for considering to create an issue!  If you could just please follow these rules, that would be great :smile:.

## General Guidelines
* Make sure your issue hasn't already been reported before opening one
* Create an issue before a PR if it relates to a new feature
* Do not open an issue on a topic unrelated to FF2
* Do not report issues on outdated versions of FF2

## Issues
* Bug reports should contain the exact version of FF2 that you experienced the bug on
	* Refer to an exact commit or build number instead of the "latest" version
	* Error logs should also be included if possible (surround the log with \`\`\`)
	* Pictures would also be helpful if the bug is graphical
	* If testing on a dev version, make sure you are using the latest source available
* Feature requests should contain a description of existing behavior and a detailed explanation of why you want this new feature
	* If possible, prove that others want this new feature as well

## Pull Requests
* Open your PR on the right branch
	* Bug fixes should go to stable, improvements to development, and breaking changes to experimental
* Do not create a feature PR unless the corresponding issue has been approved
* Only have one change per PR
	* In other words, only focus on one feature rather than two or more unrelated ones
* Create informative titles for commits (`Fix AIOOB error in XYZ` rather than `Fix`)
* Do not create superfluous commits, especially commits that have the same title
* PRs that have un-necessary commits or unhelpful titles must be squashed before they are merged
* Make sure your formatting is in line with the existing code
	* Braces on new line
	* No spaces between parentheses or most operators (=, ==, *, |, &, etc)
		* **Exception**: One space between &&, ||, ;, and ,
		* *Note*: & and | formatting rules are currently not enforced
	* Tabs, not spaces for initial whitespace
	* Use spaces to line up code
	* No tabs on newline
	* No whitespace after a line
	* No trailing newline at the end of the file
	* Bracket all conditional statements, even if it is not required (one-line if statements, for example)
	* Variable names should be camel-cased (`markdownIsStupid`)
	* Method names should be capitalized normally (`MarkNativeAsOptional`)

Formatting example:
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

	new hi;  //This line uses tabs for the initial whitespace
	new cool,  //So do these lines, but then they use spaces to line up the variable names
	    awesome,
	    wow;
	return;
}
```