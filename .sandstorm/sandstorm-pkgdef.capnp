@0x89947556060775ac;

using Spk = import "/sandstorm/package.capnp";
# This imports:
#   $SANDSTORM_HOME/latest/usr/include/sandstorm/package.capnp
# Check out that file to see the full, documented package definition format.

const pkgdef :Spk.PackageDefinition = (
  # The package definition. Note that the spk tool looks specifically for the
  # "pkgdef" constant.

  id = "0qhha1v9ne1p42s5jw7r6qq6rt5tcx80zpg1f5ptsg7ryr4hws1h",
  # Your app ID is actually its public key. The private key was placed in
  # your keyring. All updates must be signed with the same key.

  manifest = (
    # This manifest is included in your app package to tell Sandstorm
    # about your app.
    appTitle = (defaultText = "Roundcube"),

    appVersion = 11,  # Increment this for every release.

    appMarketingVersion = (defaultText = "1.1.2-3"),

    actions = [
      # Define your "new document" handlers here.
      ( title = (defaultText = "New Roundcube Mailbox"),
        nounPhrase = (defaultText = "mailbox"),
        command = .myCommand
        # The command to run when starting for the first time. (".myCommand"
        # is just a constant defined at the bottom of the file.)
      )
    ],

    continueCommand = .myCommand,
    # This is the command called to start your app back up after it has been
    # shut down for inactivity. Here we're using the same command as for
    # starting a new instance, but you could use different commands for each
    # case.

    metadata = (
      icons = (
        appGrid = (png = (
          dpi1x = embed "app-graphics/roundcube-128.png",
          dpi2x = embed "app-graphics/roundcube-256.png"
        )),
        grain = (png = (
          dpi1x = embed "app-graphics/roundcube-24.png",
          dpi2x = embed "app-graphics/roundcube-48.png"
        )),
        market = (png = (
          dpi1x = embed "app-graphics/roundcube-150.png",
          dpi2x = embed "app-graphics/roundcube-300.png"
        )),
      ),

      website = "https://roundcube.net/",
      codeUrl = "https://github.com/jparyani/roundcubemail",
      license = (openSource = gpl3),
      categories = [communications],

      author = (
        contactEmail = "jparyani@sandstorm.io",
        pgpSignature = embed "pgp-signature",
        upstreamAuthor = "Roundcube Team",
      ),
      pgpKeyring = embed "pgp-keyring",

      description = (defaultText = embed "description.md"),
      shortDescription = (defaultText = "Email client"),
      # changeLog = (defaultText = embed "CHANGELOG"),

      screenshots = [
        (width = 449, height = 360, png = embed "sandstorm-screenshot.png")
      ],
    ),
  ),

  sourceMap = (
    # Here we defined where to look for files to copy into your package. The
    # `spk dev` command actually figures out what files your app needs
    # automatically by running it on a FUSE filesystem. So, the mappings
    # here are only to tell it where to find files that the app wants.
    searchPath = [
      ( sourcePath = "." ),  # Search this directory first.
      ( sourcePath = "/",    # Then search the system root directory.
        hidePaths = [ "home", "proc", "sys",
                      "etc/host.conf",
                      "etc/nsswitch.conf", "etc/resolv.conf" ]
        # You probably don't want the app pulling files from these places,
        # so we hide them. Note that /dev, /var, and /tmp are implicitly
        # hidden because Sandstorm itself provides them.
      )
    ]
  ),

  fileList = "sandstorm-files.list",
  # `spk dev` will write a list of all the files your app uses to this file.
  # You should review it later, before shipping your app.

  alwaysInclude = ["opt/app", "usr/lib/dovecot"],
  # Fill this list with more names of files or directories that should be
  # included in your package, even if not listed in sandstorm-files.list.
  # Use this to force-include stuff that you know you need but which may
  # not have been detected as a dependency during `spk dev`. If you list
  # a directory here, its entire contents will be included recursively.
);

const myCommand :Spk.Manifest.Command = (
  # Here we define the command used to start up your server.
  argv = ["/opt/app/sandstorm-http-bridge-old", "8000", "--", "/opt/app/.sandstorm/launcher.sh"],
  environ = [
    # Note that this defines the *entire* environment seen by your app.
    (key = "PATH", value = "/usr/local/bin:/usr/bin:/bin"),
    (key = "HOME", value = "/var")
  ]
);
