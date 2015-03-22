

[[xerela](xerela.md)] refers to your Xerela workspace in Eclipse, or the directory into which you check out into from SVN.  It should contain the folders AdapterTool, Build, conf, EclipseBuild, etc.

# Barebones Development Build #
At the most basic level, all that’s required to build from source is:

  * an SVN client
  * JDK 1.5 or higher
  * Perl 5.8 or higher
  * Ant 1.7 or higher

Get the code from the SVN repository, then go to the [[xerela](xerela.md)]/Build directory and run ant clean dist dbreset.  Then go to [[xerela](xerela.md)]/dist/server and, run server.bat and browse to https://127.0.0.1:8080.

But if you’re building from source then you probably want a full develop environment.  Then you should follow the instructions below.

# Recommended Development Build #
These instructions based on a fresh Windows XP SP3 install.  You should only have to make minor adjustments for a Mac or Linux build.  If you run into any problems or have any suggestions on improving the instructions, please comment below.

## Prerequisites ##
  * JDK 1.5 or higher
  * Eclipse 3.3 or higher
  * ActivePerl 5.8 or higher
  * Ant 1.7 or higher

And the following Eclipse plugins:
| **Plugin** | **Update Site URL** | **Description** |
|:-----------|:--------------------|:----------------|
| [Eclipse-CS](http://eclipse-cs.sourceforge.net) | http://eclipse-cs.sf.net/update/ | Eclipse Checkstyle - required if you are contributing. |
| [FindBugs](http://findbugs.sourceforge.net) | http://findbugs.cs.umd.edu/eclipse | Required if you are contributing. |
| [Subclipse](http://subclipse.tigris.org) | http://subclipse.tigris.org/update_1.6.x  | Optional, but very convenient. |
| [EPIC](http://www.epic-ide.org) | http://e-p-i-c.sf.net/updates/testing | The EPIC Perl editor.  Helpful for Perl formatting. |

## Check Out Source ##

  * In Eclipse, select Window > Open Perspective > Other… > SVN Repository Exploring
  * Right-click in SVN Repositories and select New > Repository Location…
  * Enter the URL http://xerela.googlecode.com/svn/trunk/
  * Expand the root node and you’ll see 108 folders.  Each of these will be a project in your workspace.  Select all 108 folders, right-click, and select Checkout…
  * Accept the defaults and click finish.

## Build and Deploy ##

  * To make sure you have all the required Perl modules, go to the [[xerela](xerela.md)]/Build/ directory and run perlcheck.pl
  * If you have not set JAVA\_HOME to your JDK or if your JAVA\_HOME is pointing at a 64-bit JDK, then you’ll need to set the `java.home` value in the file `      [xerela]/TargetPlatform/flex/bin/jvm.config ` to `java.home=<32-BIT-JDK_ROOT>/jre`
> > Otherwise you’ll see an error like:
> > Error loading: C:\Java\jdk1.6.0\_22\jre\bin\client\jvm.dll
  * In the [[xerela](xerela.md)]/Build/ directory run ant clean dbreset.

## Eclipse Configuration ##
### Eclipse-CS ###
This is required to enforce the Xerela coding standard.  You must install the Eclipse-CS plugin listed above in prerequisites.
To configure,
  * go to Window > Preferences > Checkstyle , set General Settings to your preferences, and click New…

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-checkstyle_main.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-checkstyle_main.png)

  * Set the following:
    * Type: Project Relative Configuration
    * Name: Xerela Checkstyle
    * Location: /Build/conf/xerela\_eclipse\_cs.xml

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-checkstyle_config_props.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-checkstyle_config_props.png)

### FindBugs ###
Make sure the FindBugs plugin is installed.  No further configuration is necessary.

### Code Style Settings ###
Go to Window > Preferences > Java > Code Style > Formatter.  Import the Formatter at [[xerela](xerela.md)]/Build/conf/xerela\_codeformat.xml.

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-formatter.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-formatter.png)

### Code Template ###
Go to Window > Preferences > Java > Code Style > Code Templates.  Import the Template at [[xerela](xerela.md)]/Build/conf/xerela\_codetemplates.xml.

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-code-templates.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-code-templates.png)

### Perl Template (optional - only if you’ve installed the EPIC plugin) ###
Go to Window > Preferences > Perl EPIC > Editor > Templates.  Import the Template at [[xerela](xerela.md)]/Build/conf/xerela\_epic\_template.xml.

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-epic-template.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-epic-template.png)

### Set Target Platform ###
Go to Window > Preferences > Plug-in Development > Target Platform and add the location `${workspace_loc}\TargetPlatform\eclipse`

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-target-platform-definition.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-target-platform-definition.png)

![http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-target-platform-main.png](http://xerela.googlecode.com/svn/trunk/Documentation/Developer/img/dev_setup-target-platform-main.png)