import java.sql.*;
import com.exasol.jdbc.*;

public class Bind_variables_not_working_example
{
	public static void main(String[] args)
	{
		try { Class.forName("com.exasol.jdbc.EXADriver");
	} catch (ClassNotFoundException e) { 
            e.printStackTrace();
	}
	Connection con=null; 
	PreparedStatement stmt =null;
	try {
		con = DriverManager.getConnection( 
			"jdbc:exa:192.168.56.107:8563;schema=test",
			"sys", 
			"exasol"
			);
		//stmt = con.createStatement();
		
		stmt = con.prepareStatement( "EXECUTE SCRIPT LUASCRIPT ?" );
		//stmt.setInt(1,1);
		stmt.setString(1, "A");
		stmt.execute();
		
		
		
	} catch (SQLException e) { 
		e.printStackTrace();
	} finally {
		try {stmt.close();} catch (Exception e) {e.printStackTrace();} 
		try {con.close();} catch (Exception e) {e.printStackTrace();}
		}
	}
}