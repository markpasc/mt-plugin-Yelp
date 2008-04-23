
package Yelp::Asset;
use strict;

use MT::Util qw( encode_html );

use base qw( MT::Asset );

__PACKAGE__->install_properties({
    class_type => 'yelp',
});

__PACKAGE__->install_meta({
    # already have:
    #   label
    #   url
    #   description
    columns => [ qw(
        yelp_id
        address
        phone
        yelp_avg_rating
        photo_url
    ) ],
});

sub class_label { MT->translate('Yelp Place') }
sub class_label_plural { MT->translate('Yelp Places') }
sub file_name {}
sub file_path {}
sub on_upload { 1 }
sub has_thumbnail { 1 }

sub thumbnail_url { shift->photo_url() }

sub as_html {
    my $asset = shift;
    my ($param) = @_;

    my $html = join q{},
        q{<div class="yelp-place yelp-place-}, encode_html($asset->yelp_id), q{">},
        q{<p class="yelp-place-header"><a href="}, encode_html($asset->url), q{">}, encode_html($asset->label), q{</a></p>},
        ($asset->description
            ? (q{<p class="yelp-place-description">}, encode_html($asset->description), q{</p>})
            : ()),
        ($asset->photo_url
            ? (q{<p class="yelp-place-image"><img src="}, encode_html($asset->photo_url), q{" /></p>})
            : ()),
        q{<p class="yelp-place-address">}, join(q{<br />}, map { encode_html($_) } split /\n/, $asset->address), q{</p>},
        q{<p class="yelp-place-phone">}, encode_html($asset->phone), q{</p>},
        q{<p class="yelp-place-yelp-rating"><img src="}, MT->static_path, q{plugins/Yelp/yelp.png"> }, join(q{}, (q{&#9733;}) x int ($asset->yelp_avg_rating || 0)), q{</p>},
        q{</div>};
    return $asset->enclose($html);
}

sub from_biz_obj {
    my $class = shift;
    my ($biz) = @_;

    my %asset_field_for_biz_field = (
        name       => 'label',
        url        => 'url',
        id         => 'yelp_id',
        address1   => 'address',
        phone      => 'phone',
        avg_rating => 'yelp_avg_rating',
        photo_url  => 'photo_url',
    );

    my $asset = $class->new;
    while (my ($biz_field, $asset_field) = each %asset_field_for_biz_field) {
        $asset->$asset_field($biz->$biz_field());
    }
    $asset->set_tags(map { $_->name } @{ $biz->categories() });

    return $asset;
}

1;

