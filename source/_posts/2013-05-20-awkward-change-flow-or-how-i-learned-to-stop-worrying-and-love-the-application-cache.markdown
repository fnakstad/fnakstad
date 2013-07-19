---
layout: post
title: ! 'Awkward Change Flow or: How I Learned to Stop Worrying and Love the Application Cache'
tags: Application Cache Development Grunt.js HTML5
status: publish
type: post
published: true
comments: true
permalink: /awkward-change-flow-or-how-i-learned-to-stop-worrying-and-love-the-application-cache/
---
Snappy title, yes...? Let's just move on...

The application cache API introduced by HTML5 is a very powerful tool which is particularly useful for web applications whose intended primary use is on mobile devices. Not only can it significantly speed up the load time of your app, but if implemented correctly you can make your application work quite well even when the user is not connected to the Internet. I'm not going to write too much about how the application cache works as it has already been covered very well elsewhere. If that's what you're looking for I'd recommend the following articles:

* [Mozilla Developer Network - Using the application cache](https://developer.mozilla.org/en-US/docs/HTML/Using_the_application_cache)
* [HTML5 Rocks - A Beginner's Guide to Using the Application Cache](http://www.html5rocks.com/en/tutorials/appcache/beginner)
* [Dive Into HTML5 - Let's Take This Offline](http://diveintohtml5.info/offline.html)
* [W3C's Offical Specification - Offline Web Applications](http://www.w3.org/TR/offline-webapps)

These articles describe the API really well, and also notes several of the "gotchas" that might trip you up if you're not aware of them. If not taken into serious consideration these gotchas can make further development of your application turn into a painful and frustrating experience. So, I wanted to document a way of easing the pain.

## Automatically updating the cache manifest file when files change
One of the more annoying quirks of developing with the application cache is that it has no mechanism for detecting updates to already cached resources. It doesn't re-cache any of the files in the manifest till the contents of the manifest itself has changed. The way most people get around this is by adding a comment to the top or bottom of the manifest with a timestamp or revision number. However, constantly updating this comment every time you want the browser to recache your resource will get tedious really quick.

So, we need a way of automatically updating this comment in the manifest whenever a change has been detected in one of our cached files! To do this I prefer to use [Grunt](http://gruntjs.com), which is a tool used to run automated tasks. It has a bunch of useful plugins, and for our purposes we need the [grunt-manifest](https://github.com/gunta/grunt-manifest) and [grunt-contrib-watch](https://github.com/gruntjs/grunt-contrib-watch) packages. **grunt-manifest** enables you to define your cache manifest configuration in your Gruntfile as a JSON object and regenerate on demand, while **grunt-contrib-watch** will run any task you specify when any of the files it's watching is updated... You can probably see where this is going...

To install all the necessary packages, just run the following commands in your project folder (assuming you already have installed npm):

```
npm install -g grunt-cli
npm install grunt
npm install grunt-manifest
npm install grunt-contrib-watch
```

Next, create a `Gruntfile.js` in your project root, which is where we will define our automated tasks:

{% gist 6033441 %}

Here we define two tasks, `manifest` and `watch`. The `manifest` task will generate a new manifest file and update the timestamp in the comment at the top of the file. The `watch` task will monitor the files specified, and is configured to perform the manifest task when a change has been detected. So, now we can have the manifest be automatically generated whenever a file changes by running the command `grunt watch`. This task can yet again be made part of a separate `run-dev` task which could also fire up a local node-server, live-reload, automatic LESS compilation, etc. to remove any other tasks you do manually when starting up a development server.
