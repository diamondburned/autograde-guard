# autograde-guard

autograde-guard helps professors and instructors guarantee validity of `.github`
folders within all the repositories of an organization.

## Setting Up

1. Install [diamondburned/autograde-guard](https://github.com/diamondburned/autograde-guard).
    1. On the top-right corner of the screen, click the plus (`+`) button, then
       choose _Import repository_.
    2. Put `https://github.com/diamondburned/autograde-guard.git` as the
       repository's clone URL.
    3. Put the owner of the new repository to your organization.
    4. Name the repository something like `autograde-guard`.
    5. Choose _Private_ for the repository privacy.
    6. Click _Begin import_.
    7. You will now have a copy of autograde-guard which this guide will refer
       to as a "fork".
2. Generate a [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
   **Treat this token like it is your password.**
    1. Enable PAT for your organization. **TODO**: expand this section.
    2. Click your profile picture on the top-right and go to [_Settings_](https://github.com/settings).
    3. On the sidebar, go to [_Developer settings_](https://github.com/settings), then _Personal access
       tokens_, then _Fine-grained tokens_.
    4. Click _Generate a new token_ on the right-hand side.
    5. Fill out the token settings:
        1. Give the token any name (e.g. "autograde-guard").
        2. Set an expiration, preferably to expire at the end of the semestr.
        3. **Important**: set the _Resource owner_ to the class organization,
           then choose _All repositories_ right underneath that.
            - If you don't see your organization in the options, then your
              organization has not enabled PAT yet.
        4. Under _Permissions_, choose _Repository permissions_ and set the
           following:
            - _Actions_: read-only
                - _Contents_: read and write
    6. Click _Generate token_.
    7. Your PAT will be given to you for copying. It is recommended to put this
       into a text file temporarily, since it'll never show you the token again.
3. Install the PAT into the forked repository.
    1. Go to the fork.
    2. Go to its _Settings_ tab.
    3. In the sidebar under _Security_, go to _Secrets_ then _Actions_
       underneath it.
    4. On the right-hand side, click _New repository secret_.
    5. Set the name to `GUARD_GITHUB_TOKEN`.
    6. Set the secret to be the PAT generated above.
    7. Click _Add secret_.
4. Configure the fork.
    1. Go to the fork's code.
    2. Go to the `config.toml` file.
    3. Change `trustedUsers` under `[validate]` to `[ "GitHub" ]` for GitHub
       Classroom.
    4. Change `orgnizationName` to the name of the organization that this was
       forked to.
    5. Optionally change `excludedRepos`.
5. Test-run the validation workflow.
    1. Go to the fork.
    2. Go to its _Actions_ tab.
    3. In the sidebar, go to the _Validate .github_ action.
    4. On the right-hand side, click _Run workflow_, then click the green _Run
       workflow_ button in the popup.
    5. Refresh the page. You'll see a new workflow run that's yellow. Click
       that.
    6. Click the `validate` job.
    7. Expand the _Run validate script_ section. This prints a list of all
       tampered repositories.

## Usage

### validate.sh

TBD

### validate.tmpl.sh

TBD

## Future Work

In the future, autograde-guard might have an optional configurable feature to
automatically rollback `.github` folder every time it sees one that's tampered
with.

It might also be good if autograde-guard can render into GitHub Pages the output
of its runs. This way, it's far more convenient for professors to see whose
repositories are failing.
