use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $link;
my $embedder = LinkEmbedder->new;

$link = $embedder->get('http://catoverflow.com/cats/r4cIt4z.gif');
is ref($link), 'LinkEmbedder::Link::Basic', 'LinkEmbedder::Link::Basic';
is_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  height        => 0,
  html          => catoverflow_html(),
  provider_name => 'Catoverflow',
  provider_url  => 'http://catoverflow.com/',
  title         => 'r4cIt4z.gif',
  type          => 'photo',
  url           => 'http://catoverflow.com/cats/r4cIt4z.gif',
  version       => '1.0',
  width         => 0,
  },
  'json for catoverflow.com';

$link = $embedder->get('http://thorsen.pm/blog/');
is ref($link), 'LinkEmbedder::Link::Basic', 'LinkEmbedder::Link::Basic';
is_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  html          => thorsen_html(),
  provider_name => 'Thorsen',
  title         => 'jhthorsen - blog',
  type          => 'rich',
  url           => 'http://thorsen.pm/blog/',
  provider_url  => 'http://thorsen.pm/',
  version       => '1.0'
  },
  'json for thorsen.pm';

$link = $embedder->get(
  'http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html');
is ref($link), 'LinkEmbedder::Link::Basic', 'LinkEmbedder::Link::Basic';
is_deeply $link->TO_JSON,
  {
  author_name      => 'Per Kristian Bjørkeng',
  author_url       => 'mailto:per.kristian.bjorkeng@aftenposten.no',
  cache_age        => 0,
  html             => aftenposten_html(),
  provider_name    => 'Aftenposten',
  provider_url     => 'http://www.aftenposten.no/',
  thumbnail_height => 810,
  thumbnail_url    => 'https://ap.mnocdn.no/images/ae53dc79-22e3-41da-b64b-16ec78f42a1a?fit=crop&q=80&w=1440',
  thumbnail_width  => 1440,
  title            => 'Google har skapt kunstig intelligens som trener seg selv',
  type             => 'rich',
  url     => 'http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html',
  version => '1.0'
  },
  'json for twitter';

done_testing;

sub aftenposten_html {
  return <<'HERE';
<div class="le-card le-rich le-aftenposten">
    <a href="http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html" class="le-thumbnail">
      <img src="https://ap.mnocdn.no/images/ae53dc79-22e3-41da-b64b-16ec78f42a1a?fit=crop&amp;q=80&amp;w=1440" alt="Per Kristian Bjørkeng">
    </a>
  <h3>Google har skapt kunstig intelligens som trener seg selv</h3>
  <p class="le-description">– Vi tror det vil komme kunstig intelligens på nivå med mennesker før eller siden, men det er veldig vanskelig å si om det blir 10 eller 50 år til, sier forsker.</p>
  <div class="le-meta">
    <span class="le-author-link"><a href="mailto:per.kristian.bjorkeng@aftenposten.no">Per Kristian Bjørkeng</a></span>
    <span class="le-goto-link"><a href="http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html"><span>http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html</span></a></span>
  </div>
</div>
HERE
}

sub catoverflow_html {
  return <<'HERE';
<div class="le-photo le-catoverflow">
  <img src="http://catoverflow.com/cats/r4cIt4z.gif" alt="r4cIt4z.gif">
</div>
HERE
}

sub thorsen_html {
  return <<'HERE';
<div class="le-card le-rich le-thorsen">
    <a href="http://thorsen.pm/blog/" class="le-thumbnail-placeholder">
      <img src="http://placehold.it/200x200?text=Thorsen" alt="Placeholder">
    </a>
  <h3>jhthorsen - blog</h3>
  <div class="le-meta">
    <span class="le-goto-link"><a href="http://thorsen.pm/blog/"><span>http://thorsen.pm/blog/</span></a></span>
  </div>
</div>
HERE
}
