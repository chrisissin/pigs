import java.io.File;

import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.impl.client.DefaultHttpClient;

public class Client {
	
	public static void main( String[] args ) throws Exception
	{
		HttpClient client = new DefaultHttpClient();
		String url = "http://localhost:8080/api/audio";
		HttpPost put = new HttpPost( url );
		
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE);
		
		entity.addPart( "audio", new FileBody( new File( "voice.aif" ) ) );

		put.setEntity( entity );

		client.execute( put );
	}
	
}
