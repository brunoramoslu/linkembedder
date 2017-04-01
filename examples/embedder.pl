#!/usr/bin/env perl
use Mojolicious::Lite;

use lib 'lib';
use LinkEmbedder;

helper embedder => sub { state $e = LinkEmbedder->new };

get '/'       => 'index';
get '/oembed' => sub {
  my $c   = shift;
  my $url = $c->param('url');

  if ($c->stash('restricted') and !grep { $_ eq $url } @{$c->stash('predefined')}) {
    $c->render(json => {error => "LINK_EMBEDDER_RESTRICTED is set."});
  }
  else {
    $c->embedder->serve($c);
  }
};

app->defaults(
  restricted => $ENV{LINK_EMBEDDER_RESTRICTED} ? 1 : 0,
  predefined => [
    "http://xkcd.com/927",
    "http://catoverflow.com/cats/r4cIt4z.gif",
    "https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight",
    "http://imgur.com/gallery/ohL3e",
    "http://www.aftenposten.no",
    "https://www.instagram.com/p/BQzeGY0gd63",
    "http://ix.io",
    "http://ix.io/fpW",
    "http://catoverflow.com/",
    "http://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9",
    "https://appear.in/link-embedder-demo",
    "https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t",
    "https://metacpan.org/pod/Mojolicious",
    "https://pastebin.com/V5gZTzhy",
    "http://paste.opensuse.org/2931429",
    "http://twitter.com",
    "https://www.youtube.com/watch?v=OspRE1xnLjE",
    "https://twitter.com/jhthorsen/status/434045220116643843",
    "https://vimeo.com/154038415",
    "http://paste.scsys.co.uk/557716",
    "https://travis-ci.org/Nordaaker/convos/builds/47421379",
    "http://git.io/aKhMuA",
    "http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html",
    "spotify:track:0aBi2bHHOf3ZmVjt3x00wv",
  ]
);

app->start;

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>oEmbed example server</title>
  %= stylesheet 'https://cdnjs.cloudflare.com/ajax/libs/pure/0.6.2/pure-min.css'
  <style>
.container { max-width: 40rem; margin: 3rem auto; }
a { color: #0078e7; }
ol.predefined { display: none; }
pre.data { color: #999; margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #ddd; }
[name="url"] { width: 100%; }

.le-card {
  overflow: hidden;
  border: 1px solid #ccc;
  border-radius: 5px;
  padding: 1rem;
  margin: 0;
}

.le-image-card h3,
.le-image-card p,
.le-image-card .le-meta {
  margin-left: calc(100px + 1rem);
}

.le-card h3 {
  margin-top: 0;
}

.le-card .le-meta,
.le-card .le-meta a {
  font-size: 0.9rem;
  color: #333;
}

.le-card .le-thumbnail,
.le-card .le-thumbnail-placeholder {
  float: left;
}

.le-card .le-thumbnail img,
.le-card .le-thumbnail-placeholder img {
  width: 100px;
}

.le-card .le-meta .le-goto-link a:before {
  content: "Read more";
}

.le-author-link ~ .le-goto-link:before {
  content: "\2013\00a0";
}

.le-goto-link span {
  display: none;
}

.le-paste {
  background-color: #f8f8f8;
  max-height: 300px;
  overflow: auto;
}

.le-paste .le-meta {
  background-color: #dfdfdf;
  padding: 0.2em 0.5rem;
}

.le-paste pre {
  padding: 0.5rem;
}

.le-paste .le-provider-link:before {
  content: "Hosted by ";
}
</style>
</head>
<body>
<div class="container">
  <h1>oEmbed / LinkEmbedder example server</h1>

  %= form_for '/oembed', class => 'pure-form pure-form-stacked', begin
    % if ($restricted) {
      <p>
        <button type="button" class="pure-button pure-button-primary predefined">Render predefined</button>
      </p>
    % } else {
      <label for="form_url">URL</label>
      %= text_field 'url', value => 'http://git.io/aKhMuA', id => 'form_url'
      <span class="pure-form-message">Enter any URL, and see how it renders below</span>
      <p>
        <button type="submit" class="pure-button pure-button-primary">Render URL</button>
        <button type="button" class="pure-button pure-button-secondary predefined">Render predefined</button>
      </p>
    % }
  % end

  <h2 class="url">&nbsp;</h2>
  <div class="html">Enter an URL and hit <i>Render!</i> to see the HTML snippet here.</div>
  <pre class="data"></pre>
  <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
  %= javascript begin
var form = document.querySelector("form");

var url = location.href.match(/url=([^\&]+)/);
var predefined = <%== Mojo::JSON::to_json($predefined) %>;
var predefined_index = location.href.match(/\#(\d+)/);
predefined_index = predefined_index ? predefined_index[1] : -1;

function embed(e, url) {
  if (e.preventDefault) e.preventDefault();
  var req = new XMLHttpRequest();
  req.open("GET", form.action + "?url=" + encodeURIComponent(url));
  document.querySelector("h2.url").innerHTML = "Fetching " + url + "...";
  req.onload = function(e) {
    var oembed = JSON.parse(this.responseText);
    document.querySelector("h2.url").innerHTML = url;
    document.querySelector("div.html").innerHTML = oembed.html;

    delete oembed.html;
    document.querySelector("pre.data").innerHTML = JSON.stringify(oembed, undefined, 2);
    if (oembed.provider_name == 'Twitter') twttr.widgets.load();
  };
  req.send();
}

form.addEventListener("submit", function(e) { embed(e, form.elements.url.value); });

document.querySelector("button.predefined").addEventListener("click", function(e) {
  location.hash = ++predefined_index;
  if (!predefined[predefined_index]) predefined_index = 0;
  embed(e, predefined[predefined_index]);
});

if (predefined_index >= 0) {
  embed({}, predefined[predefined_index]);
}
else if(url) {
  embed({}, decodeURIComponent(url[1]));
}
  % end
</div>
</body>
</html>
