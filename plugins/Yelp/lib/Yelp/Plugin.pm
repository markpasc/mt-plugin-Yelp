
package Yelp::Plugin;

sub ywsid {
    return MT->component('Yelp')->get_config_value('ywsid', 'system');
}

sub dialog_search {
    my ($app) = @_;
    my $plugin = MT->component('Yelp');

    my $tmpl = $plugin->load_tmpl('dialog_search.tmpl');
    return $app->build_page($tmpl, {
        term     => $app->param('term') || '',
        location => $app->param('location')
            || $plugin->get_config_value('default_location', 'blog:' . $app->blog->id),
        error_term_required => $app->param('error_term_required'),
        error_location_required => $app->param('error_location_required'),
    });
}

sub dialog_result {
    my ($app) = @_;
    my $plugin = MT->component('Yelp');
    
    my $term = $app->param('term')
        or return $app->forward('yelp_search', error_term_required => 1);
    my $location = $app->param('location')
        || $plugin->get_config_value('default_location', 'blog:' . $app->blog->id)
        or return $app->forward('yelp_search', error_location_required => 1);

    require WebService::Yelp;
    my $yelp = WebService::Yelp->new({ ywsid => __PACKAGE__->ywsid });
    my $res = $yelp->search_review_hood({
        location => $location,
        term     => $term,
    });
    my $bizzes = $res->businesses();

    require Yelp::Asset;
    my %asset_field_for_biz_field = (
        name       => 'label',
        url        => 'url',
        id         => 'yelp_id',
        address1   => 'address',
        phone      => 'phone',
        avg_rating => 'yelp_avg_rating',
        photo_url  => 'photo_url',
    );

    my $tmpl = $plugin->load_tmpl('dialog_result.tmpl');
    return $app->listing({
        type     => 'asset',
        template => $tmpl,
        iterator => sub {
            my $biz = shift @$bizzes;
            return if !$biz;
            return Yelp::Asset->from_biz_obj($biz);
        },
        code     => sub {
            my ($obj, $row) = @_;
            $row->{$_} = $obj->$_() for qw( address yelp_id phone yelp_avg_rating photo_url );
            $row->{categories} = [ $obj->tags ];
        },
    });
}

sub dialog_create {
    my ($app) = @_;
    my $plugin = MT->component('Yelp');

    require WebService::Yelp;
    my $yelp = WebService::Yelp->new({ ywsid => __PACKAGE__->ywsid });

    ID: for my $id ($app->param('id')) {
        my $res = $yelp->search_phone({ phone => $id })
            or next ID;

        for my $biz (@{ $res->businesses() }) {
            require Data::Dumper;
            require Yelp::Asset;
            my $asset = Yelp::Asset->from_biz_obj($biz);
            $asset->blog_id($app->blog->id);
            $asset->save() or die $asset->errstr;
        }
    }

    my $tmpl = $plugin->load_tmpl('dialog_insert.tmpl');
    return $app->build_page($tmpl, {});
}

1;

