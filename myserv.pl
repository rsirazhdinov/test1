#!/usr/bin/perl
{
package MyWebServer;

use HTTP::Server::Simple::CGI;
use CGI;
use DBI;
use DBD::mysqlPP;


our @ISA = qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    '/customer.cgi' => \&customer,
	'/report.cgi' => \&report,
);

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
} else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header(-charset => 'UTF-8'),
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}

sub customer {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    my $name = $cgi->param('name');
    my $last_name = $cgi->param('last_name');
    my $phone = $cgi->param('phone');
    my $submit = $cgi->param('SUBMIT');
    my $submit2 = $cgi->param('SUBMIT2');



if ($submit && $name && $last_name && $phone){
my $dbh = DBI->connect('DBI:mysqlPP:database=sakila;host=localhost', 'root', '1234'
	           ) || die "Could not connect to database: $DBI::errstr";

	my $query = "START TRANSACTION; insert into customers.clients (c_name,c_last_name,c_status,c_phone)
values (?,?,1,?);commit;";
my $sth = $dbh->prepare($query);
$sth->execute($name,$last_name,$phone);
$dbh->disconnect();
}elsif($submit2){
	
my $dbh = DBI->connect('DBI:mysqlPP:database=sakila;host=localhost', 'root', '1234'
	           ) || die "Could not connect to database: $DBI::errstr";
my $sth = $dbh->prepare("select c_id, c_status from customers.clients;");
$sth->execute();
my %h;
	while(@row = $sth -> fetchrow_array) {
		my $p = $cgi->param($row[0]);
		$h{$row[0]} = $p if $row[1] != $p;
	}
$sth->finish;
while((my $k,$v)=each %h){
$sth = $dbh->prepare("START TRANSACTION; update customers.clients set c_status = ? where c_id = ?; commit;");
$sth->execute($v,$k);
$sth->finish;
}


	};

my $dbh = DBI->connect('DBI:mysqlPP:database=sakila;host=localhost', 'root', '1234'
	           ) || die "Could not connect to database: $DBI::errstr";

my $sth = $dbh->prepare("select * from sakila.actor limit 1");
$sth->execute;
my @row = $sth -> fetchrow_array;
$sth->finish;
    print $cgi->header(-charset => 'UTF-8'),
          $cgi->start_html("Hello"),
          $cgi->start_form ( -method  => 'GET'),
'<fieldset style="background-color:#C0C0C0; width:600px;"><legend style="background-color:white;">Add new customer:</legend>';

print "<table>
<tr><td>name</td> <td><input type=text name=name value=$name></td></tr>
<tr><td>last_name</td> <td><input type=text name=last_name value=$last_name></td></tr>
<tr><td>phone</td> <td><input type=text name=phone value=$phone></td></tr>
<tr><td></td> <td><input type=submit name=SUBMIT value=submit></td></tr>
</table></fieldset>";

	print	$cgi->end_form;

$sth = $dbh->prepare("select c_id, c_name, c_last_name, c_status, c_phone, DATE_FORMAT(c_created,'%d-%m-%Y')from customers.clients;");
$sth->execute();

print '<form method=post>';
print '<fieldset style="background-color:#C0C0C0; width:600px;"><legend style="background-color:white;">Customers:</legend>'; 
print '<table><tr><th>id</th><th>Name</th><th>Last Name</th><th>Status</th><th>Phone</th><th>Created</th></tr>';
while(@row = $sth -> fetchrow_array) {
print "<tr><td>$row[0]</td> <td>$row[1]</td> <td>$row[2]</td> <td><select size='1' name=\"$row[0]\">
    <option ${\is_selected($row[3],1)} value=1>1</option>
    <option ${\is_selected($row[3],2)} value=2>2</option>
    <option ${\is_selected($row[3],3)} value=3>3</option>
    <option ${\is_selected($row[3],4)} value=4>4</option>
   </select></td> <td>$row[4]</td> <td>$row[5]</td></tr>";
}
print '</table>';
print '<br><input type=submit name=SUBMIT2 value=SUBMIT2>';
print '</fieldset>';
print '</form>';
print $cgi->end_html;

}

	sub is_selected {
		my ($a, $b) = @_;
		if ($a == $b){
			return 'selected';
		}else{
			return undef;
		};
	}




sub report {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
    my $convers = $cgi->param('convers');
    my $submit = $cgi->param('submit');

	print $cgi->header(-charset => 'UTF-8'), $cgi->start_html;
	print "<form method=get><fieldset style='background-color:#C0C0C0; width:600px;'><legend style='background-color:white;'>Input days for conversion:</legend><input type=text name=convers id=convers value=$convers><input type=submit name=submit value=submit></fieldset></form><br>";
if($submit && $convers){
	my $dbh = DBI->connect('DBI:mysqlPP:database=sakila;host=localhost', 'root', '1234'
	           ) || die "Could not connect to database: $DBI::errstr";
my $sth = $dbh->prepare("select  SUM(IF(c_status=2,1,0))/count(*) conversion, 
 DATE_FORMAT(max(FROM_UNIXTIME( (UNIX_TIMESTAMP(c_created) div ?) * ?)),'%d-%m-%Y') as begin,
 DATE_FORMAT(max(FROM_UNIXTIME((UNIX_TIMESTAMP(c_created) div ?) * ? +?)),'%d-%m-%Y') as end
 from customers.clients group by UNIX_TIMESTAMP(c_created) div ?;
");
my $conv = $convers*24*60*60;
#my $ss = $sth->execute(join ',' => ('$conv') x 6);
my $ss = $sth->execute($conv, $conv, $conv, $conv, $conv, $conv);
print '<fieldset style="background-color:#C0C0C0; width:600px;"><legend style="background-color:white;">Conversion:</legend><table><tr><th>conversion</th><th>date_begin</th><th>date_end</th></tr>';
while(my @row = $sth->fetchrow_array){
print "<tr><td>$row[0]</td><td>$row[1]</td><td>$row[2]</td></tr>";
}
print '</table></fieldset>';


}
	print $cgi->end_html;
}

} # end of package MyWebServer

# start the server on port 8080
my $pid = MyWebServer->new(8080)->background();
print "Use 'kill $pid' to stop server.\n";




