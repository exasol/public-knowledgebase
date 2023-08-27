CREATE SCHEMA JAVA;

--/
CREATE OR REPLACE JAVA SCALAR SCRIPT HELLOWORLD() RETURNS VARCHAR(200) AS
	// This jar was generated using the following tutorial:
	// http://maven.apache.org/guides/getting-started/maven-in-five-minutes.html
	%jar /buckets/bucketfs1/test1/my-app-1.0-SNAPSHOT.jar;
	import java.io.*;
	import com.mycompany.app.App;
	class HELLOWORLD {
		static String run(ExaMetadata exa, ExaIterator ctx) throws Exception {
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			System.setOut(new PrintStream(baos));
			App.main(null);
			return baos.toString();
		}
	}
/

SELECT HELLOWORLD();