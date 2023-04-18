# Tracking Exasol metadata in a code-versioning system 
In a recent user group, I described our solution to keeping track of Exasol metadata. This article is meant to provide more details of our implementation for those who may wish to adapt parts of it.

## Background

First of all, by "Exasol metadata" I mean: table, view, function, script and schema DDL, users, roles, permissions, connections, system parameters, etc 

The problems we are trying to solve are:

1. Historicizing the metadata
	* Being able to easily see what any of the metadata was in the past
	* Being able to easily restore any portion of the metadata based on a previous snapshot
2. Being aware of all metadata changes in Exasol so that we can evaluate their impact on:
	* Security
	* Performance
3. Being able to give view authors feedback regarding
	* Best practices. Guiding them in the use of native or custom functions/scripts.
	* SQL formatting
	* Performance

Our solution, in summary, is to dump all the desired Exasol metadata on a regular basis into text files that are then stored and tracked in a code-versioning system. The versioning system handles change reviews, provides a feedback mechanism, provides an audit trail, and can be used as the source for restoring metadata from a backup. 

## Prerequisites

Our specific implementation requires being familiar with Golang and git/bitbucket however these can generally be replaced by any coding/scripting language and code-versioning system that you are comfortable with.

## How to track Exasol metadata in git

### Step 1: Decide on the update interval and scheduler

You need to decide how often you want to capture a snapshot of Exasol's metadata. Keep in mind its performance impact on Exasol. Depending on how much metadata you are capturing it can take a minute or longer to capture. We chose to capture it daily.

You'll also need a way to regularly run the job. This could be as simple as a cronjob or you can use a job scheduling app.

### Step 2: Open a branch in git/bitbucket

git uses "branches" to keep track of related changes in text files. Each branch will end up being sent to one or more reviewers for approval and so you may want to open multiple git branches, each one containing related Exasol metadata that pertains to a particular group of reviewers. For instance, changes to users, roles, and permissions could be sent to DBAs for review while changes to views could be sent to whoever is responsible for that team's views.

At the beginning of the job run you'll need to open a git branch:

`git clone <your-git/bitbucket-repo> <local-dir>`

`cd <local-dir>`

`git checkout -B <branch-name>`

The branch name should probably contain today's date and some some indication of the branch's purpose e.g "2021-11-17-USER-PERMISSIONS"

### Step 3: Export the Exasol metadata

Next you'll need to export whatever Exasol metadata you want to keep track of into text files within your local git branch. 

If you are familiar with Golang you can use  [this library](https://github.com/GrantStreetGroup/go-exasol-backup) to do so. You will need to write a Golang wrapper around the library in order to customize your mechanism for providing Exasol connection credentials and passing command-line options. This particular library will store the DDL for each database object in an individual file in a directory structure that mirror the Exasol schema. 

You can also use [Exasol's database migration SQL](https://github.com/exasol/database-migration/blob/master/exasol_to_exasol.sql) as a starting point for writing a script in the language of your choice for converting Exasol metadata to SQL/DDL that can then be saved in files within your git checkout.

Either way the end point of this step should be a set of text files in your local git directory containing the DDL representing the current state of your Exasol instance.

### Step 4: Commit any changes to git

It's possible there have been no metadata updates since the last capture so you'll need to first look for changes so that you don't send out empty branches for review:

`git status -s`

If that doesn't return any output then there have been no changes and so you can exit your job.

If there is output then you'll need to commit the changes to git:

`git add --all`

`git commit -m "Exasol metadata backup: <branch-name>"`

`git push origin <branch-name>`

At this point you can delete your local git checkout directory if you wish

`cd ../`

`rm -rf <local-dir>`

### Step 5: Send out BitBucket pull request for review

Different code-versioning systems have different ways of triggering requests for review. In BitBucket's case it can be done via their API:


```bash
curl "https://bitbucket-url/rest/api/1.0/projects/your-proj/repos/your-repo/pull-requests" \
    --user "$user:$password" \
    --header "Content-Type: application/json" \
    --data @- <<EOJ
{
   "title": "$title",
   "description": "$description",
   "fromRef": { "id": "refs/heads/$branch_name" },
   "toRef": { "id": "refs/heads/master" },
   "reviewers": [
      {"user":{"name":"..."}}
   ]
}
EOJ
```
 Here you would decide who gets to review this portion of the metadata (multiple reviewers if so configured).

### Step 6: Review the changes and provide feedback

At this point the various reviews can look over the changes and provide feedback to the view authors (or whoever maintains that particular metadata.)  

**Important**: Note that the metadata changes highlighted in the pull request represent changes *that have already been made in Exasol.*  So this is more of an "after-the-fact" review. If you what a process for requiring reviews *before* the changes are made in Exasol you could consider requiring the changes first be made in a non-production Exasol instance, followed by a review/approval, and only then applying/pushing the changes to a production instance.

### Step 7: Merge the changes

Since the changes have already been made in Exasol the concept of "failing/rejecting a pull request" doesn't really make sense. So regardless of whether the feedback is positive or negative, in the end, the pull request needs to be merged into the git trunk so that the subsequent job run can be based off of it. Bitbucket can be configured to either auto-merge pull-requests upon approval or require a separate merge step. 

## Additional Notes

If you wish you also choose to export small amounts of table or view data (the actual content, not the DDL) and store/track it in git. The Golang libary referenced above includes an option to enable this. This is handy for important lookup tables that, for instance, control security access. You would then get an alert (pull request) whenever it changes. This can be useful for catching mistakes or for generally making a wider group of people aware of changes. 

## Additional References

* Golang Exasol metadata (and small-data) backup library: [github.com/GrantStreetGroup/go-exasol-backup](https://github.com/GrantStreetGroup/go-exasol-backup)
* Exasol's table and view DDL generation SQL: [github.com/exasol/database-migration](https://github.com/exasol/database-migration/blob/master/exasol_to_exasol.sql)
* I have also attached below the bash script that we use to orchestrate this job. It's heavily customized to our use-case but you may want to use it as a starting point.

## Downloads
[exasol-bitbucket-backup.zip](https://github.com/exasol/Public-Knowledgebase/files/9928339/exasol-bitbucket-backup.zip)

