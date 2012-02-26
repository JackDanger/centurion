
# Buckets

  * projects
  * runs
  * _commits
  * _authors
  * _files
  * _methods

## Projects

  * name
  * lastRun

## Runs

  * project
  * start
  * finish
  * duration

## Commits

  * sha
  * author
  * comment
  * processedAt
  * date
  * parent
  * score
  * {other flog details}

## Commit:Files

  * name
  * nameDigest
  * commit
  * isNew
  * isRemoved
  * score
  * {other flog details}
  * lastChanged (parentsha:file in same bucket)

## Commit:File:Methods

  * name
  * file
  * nameDigest
  * fileDigest
  * commit
  * score
  * {other flog details}
  * lastChanged (parentsha:file:method in same bucket}

## Authors

  * name
  * nameDigest

