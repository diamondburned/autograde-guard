# autograde-guard

autograde-guard helps professors and instructors guarantee validity of `.github`
folders within all the repositories of an organization.

## Usage

1. Fork [diamondburned/autograde-guard](https://github.com/diamondburned/autograde-guard).
2. Generate a [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
   **Treat this token like it is your password.**
	1. Click your profile picture on the top-right and go to [*Settings*](https://github.com/settings).
	2. On the sidebar, go to [*Developer settings*](https://github.com/settings), then *Personal access
	   tokens*, then *Fine-grained tokens*.
	3. Click *Generate a new token* on the right-hand side.
	4. Fill out the token settings:
		1. Give the token any name (e.g. "autograde-guard").
		2. Set an expiration, preferably to expire at the end of the semestr.
		3. **Important**: set the *Resource owner* to the class organization,
		   then choose *All repositories* right underneath that.
		4. Under *Permissions*, choose *Repository permissions* and set the
		   following:
		    - *Actions*: read-only
		   	- *Contents*: read-only
	5. Click *Generate token*.
	6. Your PAT will be given to you for copying. It is recommended to put this
	   into a text file temporarily, since it'll never show you the token again. 
3. Install the PAT into the forked repository.
	1. Go to the fork.
	2. Go to its *Settings* tab.
	3. In the sidebar under *Security*, go to *Secrets* then *Actions*
	   underneath it.
	4. On the right-hand side, click *New repository secret*.
	5. Set the name to `GUARD_GITHUB_TOKEN`.
	6. Set the secret to be the PAT generated above.
	7. Click *Add secret*.
4. Test-run the validation workflow.
	1. Go to the fork.
	2. Go to its *Actions* tab.
	3. In the sidebar, go to the *Validate .github* action.
	4. On the right-hand side, click *Run workflow*, then click the green *Run
	   workflow* button in the popup.
	5. Refresh the page. You'll see a new workflow run that's yellow. Click
	   that.
	6. Click the `validate` job.
	7. Expand the *Run validate script* section. This prints a list of all
	   tampered repositories.

## Future Work

In the future, autograde-guard might have an optional configurable feature to
automatically rollback `.github` folder every time it sees one that's tampered
with.

It might also be good if autograde-guard can render into GitHub Pages the output
of its runs. This way, it's far more convenient for professors to see whose
repositories are failing.
