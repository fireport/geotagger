#!/usr/bin/perl
use warnings;
use LWP::Simple qw(get);
use LWP::UserAgent;
use Image::ExifTool ':Public';;
use Data::Dumper;
use XML::Simple;
$debug = 1;
use Dumpvalue;

my $street_number="";
my $route ="";
my $city="";
my $nation="";


my $exifTool = new Image::ExifTool;
$file=$ARGV[0];
if (! defined $file) {print  "usage: $0 file_name\n";exit 1};
if (! -e $file) {print "$file doesn't exists\n";exit 2};
if  (! -w $file) { print "$file isn't writable\n";exit 3};
#die "Il parametro NOME FILE necessario" if !defined $file;
#die "Il file $file non esiste\n" if  ! -e $file;
#die "Il file $file non è scivibile\n" if  ! -w $file;
#$exifTool->Options(Unknown => 1, CoordFormat=>"%.6f", Charset=>"UTF8",CharsetIPTC=>"UTF8");
$exifTool->Options(Unknown => 1, CoordFormat=>"%.6f", Charset=>"UTF8");

my $info = $exifTool->ImageInfo($file,"exif:GPSLatitude","exif:GPSLongitude");
$lat=$exifTool->GetValue("GPSLatitude",'ValueConv');
$lon=$exifTool->GetValue("GPSLongitude",'ValueConv');
# "Coordinate GPS non presenti nel file $file\n" if !defined $lat;
if (!defined $lat) { print "GPS coords not found in $file\n";exit 4};

#$lat="41.7927169";
#$lon="12.3594485";


#print "$lat $lon\n";

my $ua = LWP::UserAgent->new;
$ua->default_header(
    'Accept-Charset' => 'utf-8'
);
$ua->agent('Mozilla/5.0');

my $response = $ua->get( "http://maps.googleapis.com/maps/api/geocode/xml?latlng=$lat,$lon&sensor=true");
#my $content = $response->content;
#print "Length content is ", length $content, "\n" if $debug;

my $decoded_content = $response->decoded_content;
#print "Length decoded content is ", length $decoded_content, "\n" if $debug;


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



print  $perl_data->{'result'}[0]->{"formatted_address"}."\n";
$street_number=$perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"};
$route=$perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"};
$city=$perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"};
$nation=$perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"} if defined $perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"};

#print  $perl_data->{'result'}[0]->{"address_component"}[0]->{"long_name"}."\n";
#print  $perl_data->{'result'}[0]->{"address_component"}[1]->{"long_name"}."\n";
#print  $perl_data->{'result'}[0]->{"address_component"}[3]->{"long_name"}."\n";
#print  $perl_data->{'result'}[0]->{"address_component"}[6]->{"long_name"}."\n";
#print  $perl_data->{'result'}[0]->{"geometry"}{"location"}{"lat"}."\n";#
#
#
print "$street_number $route, $city $nation\n";



#my %tags = (
#    formatted_address => { Name => 'formatted-address',Format => 'string[0,254]' },
#);
#my $num = AddUserDefinedTags('Image::ExifTool::IPTC::ApplicationRecord', %tags);


#$success = $exifTool->SetNewValue("IPTC:formatted-address"=> $perl_data->{'result'}[0]->{"formatted_address"} );
$success = $exifTool->SetNewValue("IPTC:Sub-location"=>"$street_number, $route" );
$success = $exifTool->SetNewValue("IPTC:City"=> $city  );
$success = $exifTool->SetNewValue("IPTC:Country-PrimaryLocationName"=> $nation);
$success = $exifTool->SetNewValue("IPTC:Caption-Abstract"=> $perl_data->{'result'}[0]->{"formatted_address"});
$exifTool->WriteInfo($file);

