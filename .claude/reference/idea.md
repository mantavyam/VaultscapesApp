# Context
At this point The developer has initialised the starting point for a Flutter application with simple counter app prebuilt as boiler plate.

Important Links for the App:
- DEFAULT HOME = 'https://mantavyam.gitbook.io/vaultscapes'
- COLLABORATE FORM = 'https://mantavyam.notion.site/18152f7cde8880d699a5f2e65f87374e?pvs=105'
- FEEDBACK FORM = 'https://mantavyam.notion.site/17e52f7cde8880e0987fd06d33ef6019?pvs=105'

Other Links to be opened as screens within App:
- OPEN SEARCH (Alongside Trigger keyboard Opening also exclusive for this) = 'https://mantavyam.gitbook.io/vaultscapes?q='
- GITHUB = 'https://github.com/mantavyam/vaultscapesDB'
- DISCORD = 'https://discord.com/invite/AQ7PNzdCnC'
- HOW TO USE DATABASE? = 'https://mantavyam.gitbook.io/vaultscapes/how-to-use-database'
- HOW TO COLLABORATE? = 'https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate'
- COLLABORATORS = 'https://mantavyam.gitbook.io/vaultscapes/collaborators'  

# Task
- I want you to create a strategy from a developer's POV to create an application to bundle existing webpages compiled together as ready to view screens in a single app using Flutter. 
- The Application Flow will be spot on:
- User Opens app for first time post installation
- App Opens with Screen displaying 2 Buttons 'Get Started' and 'Explore'
	- If Clicked on:
		- 'Get Started':
			- Bottom Sheet Opens with Buttons for the Auth flows 'Continue with Google' and 'Continue with Github'
			- Auth Flow Completes
				- Set Profile Data of Name as fetched from Provider ? or Customise Now! (We are only interested in User's Email Address which is fetched from provider and for name we shall have both saved in our database ; 1 from provider originally and 1 if set custom by user)
			- User is taken to the Home Screen
			- The Bottom Navigation Bar will have 4 icons for separation of concerns as described below:  
			- HOME displays WEBPAGE as told.
			- COLLABORATE displays WEBPAGE as told.
			- FEEDBACK displays WEBPAGE as told.
			- PROFILE SECTION displays user's credentials as configured also it has 'Other Links to be opened as screens within App' as described in '#CONTEXT'.
				- Some Settings:
					- Set Semester Preference (CONSTRUCT URL DYNAMICALLY and override the Homepage URL to open the respective semester for example : 'https://mantavyam.gitbook.io/vaultscapes/sem-1' and similarly for any of the 8 semesters by altering the digit at the end)
		- 'Explore':
			- Auth Flow is skipped and User is directly taken to the Home Screen
			- PROFILE SECTION does not display user's credentials instead shows a 'Create Profile' or 'Login' buttons.

# Guidelines
- All WEB URLs are provided in the '#CONTEXT' section for reference.
- Follow the 'App Flow' as described in '#TASK'
- The App is lean and hence can be setup in 2 simple phases:
1. All Core functionality built and foundation is ready (Auth flow is mocked).
2. Authentication is Implemented in real.

# Constraints
- Do not provide Code at this point, only create a PRD.
- Do not add any functionality which is not lean, As we are targetting to build the simplest user experience without overwhelming the user.