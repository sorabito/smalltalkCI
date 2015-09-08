| scriptsPath disableUpdate exportName fileDirectoryClass fileInBlock |

scriptsPath := FileDirectory on: (Smalltalk argumentAt: 1).
scriptsPath exists ifFalse: [
  Transcript show: 'Scripts path does not exist.'.
  ^ false ].

fileInBlock := [ :fileName |
    scriptsPath readOnlyFileNamed: fileName
      do: [ :fileStream | fileStream fileIn ] ].

fileInBlock value: 'MetacelloBuilderTravisCI.st'.
fileInBlock value: 'TravisCITranscriptStream.st'.
fileInBlock value: 'CommandLineToolSet.st'.

"Install TravisCITranscriptStream"
Smalltalk at: #Transcript put: TravisCITranscriptStream new.

"Initialize exit code"
Smalltalk at: #travisCIExitCode put: 0.

disableUpdate := Smalltalk argumentAt: 2.
disableUpdate = 'true' ifFalse: [
  "Update Squeak image"
  Smalltalk at: #MCMcmUpdater ifPresent: [ :updater |
    [ updater updateFromServer ]
      on: Warning do: [ :ex | ex resume: true ]] ].

"Get the Metacello configuration (for Squeak users)"
Installer gemsource
    project: 'metacello';
    addPackage: 'ConfigurationOfMetacello';
    install.

"Bootstrap Metacello Preview, using mcz files (#'previewBootstrap' symbolic version"
((Smalltalk at: #ConfigurationOfMetacello) project 
  version: #'previewBootstrap') load.

"Load the Preview version of Metacello from GitHub"
(Smalltalk at: #Metacello) new
  configuration: 'MetacelloPreview';
  version: #stable;
  repository: 'github://dalehenrich/metacello-work:configuration';
  load.

"Now load latest version of Metacello"
(Smalltalk at: #Metacello) new
  baseline: 'Metacello';
  repository: 'github://dalehenrich/metacello-work:master/repository';
  get.
(Smalltalk at: #Metacello) new
  baseline: 'Metacello';
  repository: 'github://dalehenrich/metacello-work:master/repository';
  load.

"Only keep the latest changes"
Smalltalk condenseChanges.

"Export and quit image"
exportName := 'TravisCI.image'.
Smalltalk at: #WorldState ifPresent: [:global |
  global addDeferredUIMessage: [
    Smalltalk at: #SmalltalkImage ifPresent: [:image |
      image current saveAs: exportName.
      "Snapshot image again but close this time"
      image current snapshot: true andQuit: true ]]].
!