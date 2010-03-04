use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Finance::Card::Citibank',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'passthrough',
    requires           => {
        'Carp'                     => 0,
        'WWW::Mechanize'           => 1.00,
        'Class::Accessor::Fast'    => 0,
        'HTML::TreeBuilder::XPath' => 0,
        'HTML::Element'            => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0,
    },
);
$build->create_build_script;

