package Catalog::Main::Result::location;
		use base qw( DBIx::Class::Core );
		__PACKAGE__->table('location');
		__PACKAGE__->add_columns(qw / loc_full file_md5 loc_name loc_vol loc_path loc_ext /);
		__PACKAGE__->set_primary_key('loc_full');
        __PACKAGE__->belongs_to('file_md5' => 'Catalog::Main::Result::file');

1;

