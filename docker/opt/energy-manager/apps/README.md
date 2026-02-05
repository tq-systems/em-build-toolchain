# Introduction
Here are the Makefiles for the application projects. First, the minimum requirements for a Makefile
from an app project are shown, then the individual files are described in more detail.

# App project
## Mandatories
From make's point of view, only the following is required to be able to build an app
from an app project:

| Entry                                     | Description                            |
|-------------------------------------------|----------------------------------------|
| APP_PRETTY_NAME                           | Pretty name of the application         |
| DESCRIPTION                               | Description of the application         |
| include /opt/energy-manager/apps/Makefile | Toolchain's app Makefile as entrypoint |

## Example

Example of a simple app Makefile:

    APP_PRETTY_NAME = My application
    DESCRIPTION = My application gets things done.

    include /opt/energy-manager/apps/Makefile

## Build command

    make prepare && make all

### Build debuggable apps
By default, debug symbols are stripped from Go apps to save space. For
debugging, apps can be built with debug symbols:

    make prepare && make all-debug

### Upgrade dependencies
Upgrades the frontend/backend dependencies and the toolchain version.

    make upgrade-deps

# Files
For each Makefile, under the description, there can be a table with variables that may be of interest.
If necessary, these variables can be adjusted in the Makefile of the app project.

## Makefile
This is the entrypoint of a Makefile in an app project, it includes more Makefiles provided
by the toolchain and described below.

| Key                   | Default value             | Description                          |
|-----------------------|---------------------------|--------------------------------------|
| APP_ID                | (derived from directory)  | Unique app ID                        |
| VERSION               | (Set from 'git describe') | Version of app                       |
| FRONTEND_BUILD        | yarn                      | Frontend build mechanism             |
| BACKEND_BUILD         | go-mod                    | Backend build mechanism              |
| SERVICE_BUILD         | (1 or 0)                  | Build systemd service file           |
| ESSENTIAL             | 0                         | Essential apps cannot be uninstalled |
| AUTOSTART             | 1                         | Automatically start of app           |

## backend-cmake.mk
This Makefile provides the C/C++ backend build.

## backend-go-mod.mk
This Makefile provides the Go (Golang) backend build.

## deploy.mk
This Makefile provides the app deployment. The variables DEPLOY_SERVER and DEPLOY_DIR
need to be set via make command or environment.

| Key                   | Default value | Description                        |
|-----------------------|---------------|------------------------------------|
| DEPLOY_IN_VARIANT_DIR | (empty)       | Deploy app in variant subdirectory |

## docs.mk
This Makefile provides changelog handling.

## frontend-yarn.mk
This Makefile provides yarn frontend build.

## integration.mk
This Makefile provides targets for tests with cypress, robot and shell scripts.

## package.mk
This Makefile provides the Energy Manager package build (*.empkg).

| Key                   | Default value                  | Description                                    |
|-----------------------|--------------------------------|------------------------------------------------|
| SERVICE_EXTRA_UNIT    | (empty)                        | Extend default unit in systemd service file    |
| SERVICE_EXTRA_SERVICE | (empty)                        | Extend default service in systemd service file |
| SERVICE_CONTENT       | (Collection of default values) | Entire content of systemd service file         |

## Path permissions

An app may require read/write or read-only access permissions to various directories in order to function properly.
There are three basic directories that most apps have read/write access via ownership of the app-user.
Hence these directores are called 'own' directories:
* `/run/em/apps/${APP_ID}`
* `/cfglog/apps/${APP_ID}`
* `/data/apps/${APP_ID}`

This is likewise true for apps run under non-root namespace (sandboxed app).
For sandboxed app-users the ownership of the 'own' directories as well as other directory accesses
must be setup on the running system.
Runtime tools will grant these permissions according to path definitions in the app makefile.

In order to access 'own' directories, use the variable `MANIFEST_OWN_PATHS`.
By default `/run/em/apps/${APP_ID}` and `/cfglog/apps/${APP_ID}` are pre-defined and no additional
definition is required if read/write access to only these two 'own' directories is sufficient.
If needed, the additional 'own' path can be requested as follows:
```
MANIFEST_OWN_PATHS = \
	/data/apps/${APP_ID}
```
The toolchain combines the default and the additional paths to a full list for the runtime tools.

Apps may also request read/write or read-only access to other directories.
These are granted via access control list (ACL) entries and are defined in the app makefile:
```
MANIFEST_RW_PATHS = \
	/foo/bar \
	/foo/baz
```
* Or for read-only directories:
```
MANIFEST_RO_PATHS = \
	/foo/qux \
	/foo/quux
```

The toolchain places a JSON-formatted list of all permission requirements in the app manifest.

## App classification

Apps can be classified by two parameters in the App makefiles:
- ESSENTIAL
- APPCLASS

### ESSENTIAL
- The app is necessary for the elemental functions of the device
  (web frontend, update, button handling, teridian service, etc.)
- App cannot be disabled or uninstalled.
- Defined by 'ESSENTIAL=1' in the Makefile which is translated to "essential":true in the app manifest.

### APPCLASS

AppClass controls the systemd target that the app is started for.

#### Core app
- Starts for systemd target multi-user.target.
- Defined by 'APPCLASS=core' in the Makefile, which is translated to "appclass":"core" in app manifest.
- The empkg app generator then assigns the systemd target.

#### Time app
- App that requires valid timestamps from the system belongs in this class.
- It is started for target em-app-time.target and restarted when time gets valid or invalid.
- Defined by 'APPCLASS=time' in the Makefile, which is translated to "appclass":"time" in app manifest.
- The empkg app generator then assigns the systemd target.

#### No-Time app
- All other apps are "no-time" apps, which start for target em-app-no-time.target.
- Defined by 'APPCLASS=no-time' in the Makefile or without any definition of APPCLASS.
- The empkg app generator assigns the systemd target when the other options are not set.

## systemd launch target tree

The order of the systemd targets for which the apps are started is the following (from left to right):
```
   multi-user.target -------------------------------------------------------- default.target (system boot finished)
em-app-before.target ------ em-app-time.target --------- em-app.target -----´
                     `----- em-app-no-time.target -----´
```

## Bundle view on apps
In the perspective of bundles, apps can be:
- Base app:
  Set of apps needed to operate the device. A base app is defined in base-latest.yml
  (/opt/energy-manager/emit/base-latest.yml in toolchain docker image).
- Bundle app:
  Specific app required for the functions features in that bundle.
  Defined in the bundle yaml file.

## Naming convention for Git submodule paths

Git submodules are used for different purposes, such as including build, test or development
dependencies. For some applications, such as a build archive, it's necessary to fetch only certain
dependencies. Therefore, a naming convention with prefixes is introduced for certain applications
to allow filtering.

Here is a list of common prefixes with a status:

| Prefix             | Application              | Status     |
|--------------------|--------------------------|------------|
| backend/deps       | cmake build dependencies | productive |
| test               | test dependencies        | WIP        |

The `productive` status means, that the prefix must be used.

The `WIP` status means that ignoring the naming convention has no effect yet,
but using the prefix is ​​recommended.

The frequently used submodule `frontend/container` is not mentioned here because it will soon be
removed from apps. Its functionality will be moved to a make target.

## Firewall configuration

The em-firewall is a firewall that is used to protect the system from unwanted network traffic.
The configuration is done by adding conf files into /run/em/etc/nftables.d/ directory.
A restrictive set of firewall rules is added by the core image. Apps can add their own rules to this set.
The firewall rules can be changed in the Makefile of an app.
To configure a simple firewall rule for an app, the following variables can be used in the Makefile:

| Key                   | Default value | Description                                      |
|-----------------------|---------------|--------------------------------------------------|
| EM_FW_ALLOW_PORTS     | (empty)       | Port to be opened in the firewall                |
| EM_FW_ALLOW_PROTOCOLS | (empty)       | Protocol to be opened in the firewall (tcp/udp)  |
| EM_FW_ALLOW_DIRECTION | inbound       | Direction of the firewall rule (inbound/outbound)|

To set a more complex rule the variable `FILE_EM_FW_CONF` can be used to add a custom conf file.
This overrides the settings of the above variables.

The handling of the configuration files is done via the `em-firewall` service.
The firewall can be restarted with the command:
```
systemctl restart em-firewall
```

The firewall can be stopped with the command:
```
systemctl stop em-firewall
```

### Naming convention

The firewall rules are loaded sorted by filename. The first one loaded is 00-em-firewall-init.conf
from the core image. Static rules from the apps are named 20_<APP_ID>.conf. Dynamic rules are named
40-*.conf from the firewall package in internal-go-utils. Rules from the preset apps can be named
arbitrarily to allow modification of app and core image configs.

### Dynamic Port configuration

In the internal-go-utils repository a firewall package is provided to dynamically open and close ports.
If the application to use the firewall package is sandboxed the path `/run/em/etc/nftables.d/` must
be added to MANIFEST_RW_PATHS (see above).

### Debugging
In order to identify the necessary ports to open for an app, either study the app source
or use the firewall_logging feature of the devel app to get a log of the packets dropped by the firewall.
