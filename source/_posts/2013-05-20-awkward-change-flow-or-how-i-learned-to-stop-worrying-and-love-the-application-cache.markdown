---
layout: post
title: ! 'Awkward Change Flow or: How I Learned to Stop Worrying and Love the Application
  Cache'
tags:
- Application Cache
- Development
- Grunt.js
- HTML5
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  _syntaxhighlighter_encoded: '1'
---
Snappy title, yes...? Let's just move on...

The application cache API introduced by HTML5 is a very powerful tool which is particularly useful for web applications whose intended primary use is on mobile devices. Not only can it significantly speed up the load time of your app, but if implemented correctly you can make your application work quite well even when the user is not connected to the Internet. I'm not going to write too much about how the application cache works as it has already been covered very well elsewhere. If that's what you're looking for I'd recommend the following articles:
<ul>
	<li><a href="https://developer.mozilla.org/en-US/docs/HTML/Using_the_application_cache">Mozilla Developer Network - Using the application cache</a></li>
	<li><a href="http://www.html5rocks.com/en/tutorials/appcache/beginner">HTML5 Rocks - A Beginner's Guide to Using the Application Cache</a></li>
	<li><a href="http://diveintohtml5.info/offline.html">Dive Into HTML5 - Let's Take This Offline</a></li>
	<li><a href="http://www.w3.org/TR/offline-webapps/">W3C's Offical Specification - Offline Web Applications</a></li>
</ul>
These articles describe the API really well, and also notes several of the "gotchas" that might trip you up if you're not aware of them. If not taken into serious consideration these gotchas can make further development of your application turn into a painful and frustrating experience. So, I wanted to document a way of easing the pain.
<h4>Automatically updating the cache manifest file when files change</h4>
One of the more annoying quirks of developing with the application cache is that it has no mechanism for detecting updates to already cached resources. It doesn't re-cache any of the files in the manifest till the contents of the manifest itself has changed. The way most people get around this is by adding a comment to the top or bottom of the manifest with a timestamp or revision number. However, constantly updating this comment every time you want the browser to recache your resource will get tedious really quick.

So, we need a way of automatically updating this comment in the manifest whenever a change has been detected in one of our cached files! To do this I prefer to use <a href="http://gruntjs.com/">Grunt</a>, which is a tool used to run automated tasks. It has a bunch of useful plugins, and for our purposes we need the <a href="https://github.com/gunta/grunt-manifest">grunt-manifest</a> and <a href="https://github.com/gruntjs/grunt-contrib-watch">grunt-contrib-watch</a> packages. <strong>grunt-manifest</strong> enables you to define your cache manifest configuration in your Gruntfile as a JSON object and regenerate on demand, while <strong>grunt-contrib-watch</strong> will run any task you specify when any of the files it's watching is updated... You can probably see where this is going...

To install all the necessary packages, just run the following commands in your project folder (assuming you already have installed npm):

<code>npm install -g grunt-cli</code>
<code>npm install --save-dev grunt</code>
<code>npm install --save-dev grunt-manifest</code>
<code>npm install --save-dev grunt-contrib-watch</code>

Next, create a <code>Gruntfile.js</code> in your project root, which is where we will define our automated tasks:

<pre>
[javascript]
module.exports = function(grunt) {

    // Load plugins
    grunt.loadNpmTasks('grunt-manifest');
    grunt.loadNpmTasks('grunt-contrib-watch');

    // Make a list of paths/files to cache
    var cache = ['./public/js/*', './public/img/*', './public/css/*'];

    grunt.initConfig({

        // Define how your manifest file should be constructed
        manifest: {
            generate: {
                options: {
                    network: ['http://*', 'https://*'],
                    timestamp: true
                },
                src: cache,
                dest: 'manifest.appcache'
            }
        },

        // Now setup the watch task to monitor the same files
        // that are referenced in the CACHE section of your
        // manifest, and fire the &quot;manifest&quot; task whenever
        // a change is detected
        watch: {
            scripts: {
                files: cache,
                tasks: ['manifest']
            }
        }
    });

};
[/javascript]
</pre>

Here we define two tasks, <code>manifest</code> and <code>watch</code>. The <code>manifest</code> task will generate a new manifest file and update the timestamp in the comment at the top of the file. The <code>watch</code> task will monitor the files specified, and is configured to perform the manifest task when a change has been detected. So, now we can have the manifest be automatically generated whenever a file changes by running the command <code>grunt watch</code>. This task can yet again be made part of a separate <code>run-dev</code> task which could also fire up a local node-server, live-reload, automatic LESS compilation, etc. to remove any other tasks you do manually when starting up a development server.
