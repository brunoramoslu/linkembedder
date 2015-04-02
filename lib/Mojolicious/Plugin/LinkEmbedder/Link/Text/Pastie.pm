package Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastie;

=head1 NAME

Mojolicious::Plugin::LinkEmbedder::Link::Text::Pastie - pastie.org link

=head1 DESCRIPTION

This class inherit from L<Mojolicious::Plugin::LinkEmbedder::Link::Text>.

=head1 OUTPUT HTML

This is an example output:

  <pre class="link-embedder text-paste">$txt</pre>

=cut

use Mojo::Base 'Mojolicious::Plugin::LinkEmbedder::Link::Text';

=head1 ATTRIBUTES

=head2 media_id

  $str = $self->media_id;

=cut

has media_id => sub {
  local $_ = shift->url->path->to_string;
  return $1 if m!(?:pastes/)?(\d+)!;
  return '';
};

=head2 provider_name

=cut

sub provider_name {'pastie.com'}

=head1 METHODS

=head2 learn

=cut

sub learn {
  my ($self, $c, $cb) = @_;
  my $raw_url = $self->raw_url or return $self->SUPER::learn($c, $cb);

  $self->ua->get(
    $raw_url,
    sub {
      my ($ua, $tx) = @_;
      if ($tx->success) {
        $self->{text} = $tx->res->dom->at('pre')->content;
        $self->{text} =~ s!<br>!\n!g;
        $self->{text} =~ s!<!&lt;!g;
      }
      $self->$cb;
    },
  );
}

=head2 pretty_url

=cut

sub pretty_url {
  my $self = shift;
  my $media_id = $self->media_id or return $self->SUPER::pretty_url;

  Mojo::URL->new("http://pastie.org/pastes/$media_id");
}

=head2 raw_url

=cut

sub raw_url {
  my $self = shift;
  my $media_id = $self->media_id or return;

  Mojo::URL->new("http://pastie.org/pastes/$media_id/text");
}

=head1 AUTHOR

Jan Henning Thorsen

=cut

1;
