---
layout: post
title: Application Cache Update Process State Diagram
tags:
- Application Cache
- Development
status: publish
type: post
published: true
meta:
  _edit_last: '1'
---
Here's a quick  little follow-up to my last post about the Application Cache. How the browser checks and fetches the cache can be a little confusing at first, so I made a state diagram to keep track of the different states the Application Cache might be in and the events that change said state.
<a href="http://www.frederiknakstad.com/wp-content/uploads/2013/05/ps_neutral.png"><img class="alignnone size-full wp-image-290" alt="ps_neutral" src="http://www.frederiknakstad.com/wp-content/uploads/2013/05/ps_neutral.png" width="16" height="16" /></a> <a href="http://www.frederiknakstad.com/wp-content/uploads/2013/05/appCache_stateDiag.png"><img class="alignnone size-medium wp-image-313" alt="appCache_stateDiag" src="http://www.frederiknakstad.com/wp-content/uploads/2013/05/appCache_stateDiag-495x444.png" width="495" height="444" /></a>
Well, it's not awfully complicated, but it's nice to have a visual aid when debugging. The guard conditions indicate whether there already exists an old version of the application cache or not.
