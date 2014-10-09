#!/usr/bin/perl
use warnings;
use LWP::Simple qw(get);
use LWP::UserAgent;
use Image::ExifTool ':Public';;
use Data::Dumper;
use XML::Simple;
use Image::Magick;
use File::Basename;
use Dumpvalue;
use Color::Calc ();
use Getopt::Long;
use Pod::Usage;

my $street_number="";
my $route ="";
my $city="";
my $nation="";
my $perl_data="";
my @suffixlist=(".jpg",".JPG");
my $file_extension="png";
my $exifTool = new Image::ExifTool;
$exifTool->Options(Unknown => 1, CoordFormat=>"%.6f", Charset=>"UTF8",DateFormat => '%H:%M:%S  %a %e/%b/%Y');
my $cc = new Color::Calc( 'ColorScheme' => 'X', OutputFormat => 'hex' );


GetOptions ("debug" => \$debug, # numeric
			"ext:s" => \$file_extension, # string
			"force" =>\$force,
			"help|?" =>\$help
			) # flag
 ||  pod2usage(3);


pod2usage(3) if $help;




#$file=$ARGV[0];
#$files=<$ARGV[0]>;
foreach (@ARGV){
	$file=$_;



	if (! defined $file) {print  "usage: $0 file_name\n";exit 1};
	if (! -e $file) {print "$file doesn't exists\n";exit 2};
	if  (! -w $file) { print "$file isn't writable\n";exit 3};
	#die "Il parametro NOME FILE necessario" if !defined $file;
	#die "Il file $file non esiste\n" if  ! -e $file;
	#die "Il file $file non è scivibile\n" if  ! -w $file;
	#$exifTool->Options(Unknown => 1, CoordFormat=>"%.6f", Charset=>"UTF8",CharsetIPTC=>"UTF8");


	#open (FILE, "colors.txt") || die "Non trovo il file colors.txt";
	#while (<FILE>)
	#{
	#        next if /^\s*#/;
	#
	#                ($color_name, $red, $green, $blue)=split(/:|s+ /);
	#($color_name, $red, $green, $blue) = sscanf("%s %n %n:%n"); # input defaults to $_
	#                $colors{$color_name}{red}=>$red;
	#                $colors{$color_name}{green}=>$green;
	#                $colors{$color_name}{blue}=>$blue;

	#}
	#close FILE;
	
	my $lat=0; # 
	my $info = $exifTool->ImageInfo($file,"exif:GPSLatitude","exif:GPSLongitude",'ExifImageWidth', 'ExifImageHeight');
	my $lat=$exifTool->GetValue("GPSLatitude",'ValueConv');
	my $lon=$exifTool->GetValue("GPSLongitude",'ValueConv');
	my $date=$exifTool->GetValue("DateTimeOriginal");
	my $width=$exifTool->GetValue("ExifImageWidth");
	my $height=$exifTool->GetValue("ExifImageHeight");
	my $x_offset=$width*3/100; #to ensure that watermark will be printed, offset must be at least 3% of image width
	my $y_offset=$height*3/100; #to ensure that watermark will be printed, the offset must be at least 3% of image height
	print "$date $width $height\n" if $debug;

	# "Coordinate GPS non presenti nel file $file\n" if !defined $lat;
	if (defined $lat) { 


		
		print "Latitude: $lat Longitude: $lon\n" if $debug;

		my $ua = LWP::UserAgent->new;
		$ua->default_header(
			'Accept-Charset' => 'utf-8'
		);
		$ua->agent('Mozilla/5.0');

		my $response = $ua->get( "http://maps.googleapis.com/maps/api/geocode/xml?latlng=$lat,$lon&sensor=true");
		#my $content = $response->content;
		#print "Length content is ", length $content, "\n" if $debug;

		my $decoded_content = $response->decoded_content;
		print "Length decoded content is ", length $decoded_content, "\n" if $debug;


		#$Data::Dumper::Indent = 1;
		#print Dumper ($response->content) ;
		#exit;

		my $perl_data=XMLin($response->content, keyattr=>{type=>"address_component"});
		#$Data::Dumper::Indent = 0;
		#print Dumper($perl_data);
		#print "Dumpvalue:\n";
		#Dumpvalue->new->dumpValue( $perl_data );
		#exit;



		if ($perl_data->{'status'} ne "OK"){print "No address found for this coords: lat $lat lon:$lon in $file\n";exit 5};



		print  "Formatted address: ".$perl_data->{'result'}[0]->{"formatted_address"}."\n" if $debug;

		$street_number=$perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"};
		$route=$perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"};
		$city=$perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"};
		$nation=$perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"};
		$formatted_address=$perl_data->{'result'}[0]->{"formatted_address"};

		#print  $perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"}."\n";
		#print  $perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"}."\n";
		#print  $perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"}."\n";
		#print  $perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"}."\n";
		#print  $perl_data->{'result'}[0]->{"geometry"}{"location"}{"lat"}."\n";#
		#
		#
		#print "$street_number $route, $city $nation\n";



		#my %tags = (
		#    formatted_address => { Name => 'formatted-address',Format => 'string[0,254]' },
		#);
		#my $num = AddUserDefinedTags('Image::ExifTool::IPTC::ApplicationRecord', %tags);


		$success = $exifTool->SetNewValue("IPTC:Sub-location"=>"$street_number, $route" );
		$success = $exifTool->SetNewValue("IPTC:City"=> $city  );
		$success = $exifTool->SetNewValue("IPTC:Country-PrimaryLocationName"=> $nation);
		$success = $exifTool->SetNewValue("IPTC:Caption-Abstract"=> $formatted_address);
		$exifTool->WriteInfo($file);
	}
	else
	{
		print "GPS coords not found in $file\n";
			
	}
	$image=Image::Magick->new;
	$err=$image->Read($file);



	($x_ppem, $y_ppem, $ascender, $descender, $text_width, $text_height, $max_advance)
			 = $image->QueryFontMetrics(font=>'calibri.ttf',antialias=>'true', pointsize=>50,text=> $date);

	print "text_width: $text_width text_height: $text_height\n" if $debug; 

	($red,$green,$blue)=parsepixel($x_offset,$y_offset,$x_offset+$text_width,$y_offset+$text_height);
	$text_color= $cc->contrast(sprintf("#%02X%02X%02X", $red, $green, $blue));
	print "text color: $text_color\n"  if $debug;

	$image->Annotate(font=>'calibri.ttf', gravity=>'NorthWest', pointsize=>50, x=>$x_offset,y=>$y_offset,fill=>"#".$text_color,antialias=>'true',text=> $date);

	if (defined  $formatted_address)
	{
		($x_ppem, $y_ppem, $ascender, $descender, $text_width, $text_height, $max_advance)
			 = $image->QueryFontMetrics(font=>'calibri.ttf',antialias=>'true', pointsize=>50,text=> $formatted_address);

		print "text_width: $text_width text_height: $text_height\n" if $debug;

		($red,$green,$blue)=parsepixel($width-$text_width-$x_offset,$height-$text_height-$y_offset,$width-$x_offset,$height-$y_offset);
		print "red: $red green: $green blue: $blue\n"  if $debug;;

		$text_color= $cc->contrast(sprintf("#%02X%02X%02X", $red, $green, $blue));	
		print "text color: $text_color\n"  if $debug;
		$image->Annotate(font=>'calibri.ttf', gravity=>'SouthEast',pointsize=>50, x=>$x_offset,y=>$y_offset,fill=>"#".$text_color,antialias=>'true',text=> $formatted_address);
	}

	$save_file=basename($file,@suffixlist).".".$file_extension;
	print "saved filename: $save_file\n"  if $debug;

	if ( -e $save_file && ! $force)
	{
		print "Output file ".$save_file." exists and force flag not set. Skipping...\n";
	}
	else
	{
		$err=$image->Write($save_file);
		warn "$err" if "$err";
	}
}


sub parsepixel
{
    $xstart=$_[0];
    $xwidth=$_[2];
    $ystart=$_[1];
    $yheight=$_[3];
	$redtotal=0;
	$bluetotal=0;
	$greentotal=0;
	$pixelcount=0;


        print "$xstart,$xwidth,$ystart,$yheight\n" if $debug;

        for ($x=$xstart;$x<=$xwidth;$x++)
        {
                for ($y=$ystart;$y<=$yheight;$y++)
                {
                        #print "$x $y\n";
                        ($red,$blue,$green)=$image->GetPixel(x=>$x,y=>$y);
                        $redtotal+=$red;
                        $bluetotal+=$blue;
                        $greentotal+=$green;
                        $pixelcount++;
                        #print "$red,$blue,$green\n";
                }
         }

        print "redtotal: $redtotal bluetotal: $bluetotal greentotal: $greentotal pixelcount: $pixelcount\n"  if $debug;

	return int($redtotal/$pixelcount*255), int($greentotal/$pixelcount*255), int($bluetotal/$pixelcount*255);

                        #
       
}
__END__


=head1 NAME
geotagger - watermark date and street address from jpeg exif data
=head1 SYNOPSIS
geotagger [options] [file ...]
Options:
-help brief help message

=head1 OPTIONS
=over 8
=item B<-help>
Print a brief help message and exits.
=item B<-force>
Force overwriting of input file
=item B<-ext>
Output extension of file. Default to .png to reduce jpg losses
=item B<-debug>
Output useful debug infos
=back
=head1 DESCRIPTION
B<This program> will read the given input file(s) and watermark
snapshot date and real address of photo using gps data taken from exif tags.
The magic is made using google maps api v3 :-)
=cut
