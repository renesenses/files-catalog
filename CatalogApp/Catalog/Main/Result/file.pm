package Catalog::Main::Result::file;
		use base qw( DBIx::Class::Core );
		__PACKAGE__->table('file');
		__PACKAGE__->add_columns(qw / file_md5 file_size file_type file_nbocc file_time /);
		__PACKAGE__->set_primary_key('file_md5');
        __PACKAGE__->has_many('locations' => 'Catalog::Main::Result::location');
1;
