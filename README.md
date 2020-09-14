
## Building PHH-based 420rom GSIs ##

To get started with building GSIs

First, open a new Terminal window, which defaults to your home directory.  Clone the modified treble_experimentations repo there:

    git clone ssh://git@github.com/420rom/treble_experimentations

Create a new working directory for your 420rom build and navigate to it:

    mkdir 420rom; cd 420rom

Initialize your 420rom workspace:

    repo init -u ssh://git@github.com/420rom/android.git -b 420rom-10

Clone the modified treble patches and this repo:

    git clone ssh://git@github.com/420rom/treble_patches -b 420rom-10
    git clone ssh://git@github.com/420rom/treble_build_420rom -b 420rom-10

Finally, start the build script:

    bash treble_build_420rom/buildbot_treble.sh

Be sure to update the cloned repos from time to time!