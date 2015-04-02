# catz web application engine

Catz is the web application engine that runs [catza.net](http://catza.net/), the world's most advanced cat show photo service. Developing Catz is a non-paid hobby. It is targeted only to one specific use and is not a general-purpose software.

The project is provided as open source because
* it is an example of a Perl web application using Mojolicious MVC framework
* maybe somebody learns something by looking at the code
* sharing the source code encourages me to write better code
* catza.net fans can see how catza.net works

If you get the code you don't get a working system since following parts are not distributed.

| file or path | purpose |
| ------------- | ------------- |
| /db | the SQLite database that is required by the system to run |
| /lib/conf.pl | the system configuration module |
| /lib//text.txt | the visible text strings for pages |
| /tmpl/content | content-heavy templates to provide textual pages |
| /data/newsmeta.txt | the tagged text source data file for news |
| ../static | the photos and static assets served by the service | 

Here are some of the key points where to start browsing the source code.

| file or path | purpose |
| ------------- | ------------- |
| /lib/Catz/App.pm | the Mojolicious application |
| /lib/Catz/Ctrl | the controllers where Base.pm is the base controller |
| /lib/Catz/Data | data related procedural modules providing caching functionality, page styles, search syntax handling etc. |
| /lib/Catz/Load | procedural modules used only at data load time, not at runtime |
| /lib/Catz/Model | the models based where Base.pm is the base model |
| /lib/Catz/Util | procedural utility modules used all over the service |
| /script/create_master.sql | the database creation script |
| /script/load.pl | the data loading script |
| /script/run.pl | the script that fires up the application |
| /t | the functional tests run against the application |
| /tmpl | Mojolicious ep templates |
| /data | the tagged text source data files (note that they are updated only with software releases which is much lower pace than they actually change) |

[Read more about Catz at heikkisiltala.net](http://heikkisiltala.net/en/tag:catz?do=showtag&tag=Catz).
