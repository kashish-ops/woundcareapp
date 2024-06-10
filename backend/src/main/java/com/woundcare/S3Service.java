import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.S3Object;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

@RestController
@RequestMapping("/s3")
public class S3Service {

    private final AmazonS3 s3Client;

    @Value("${woundcare}")
    private String bucketName;

    public S3Service(AmazonS3 s3Client) {
        this.s3Client = s3Client;
    }

    @PostMapping("/upload")
    public String uploadFile(@RequestParam("test.txt") MultipartFile file) throws IOException {
        File tempFile = convertMultiPartFileToFile(file);
        String fileName = file.getOriginalFilename();
        s3Client.putObject(new PutObjectRequest(bucketName, fileName, tempFile)
                .withCannedAcl(CannedAccessControlList.PublicRead));
        tempFile.delete();
        return "File uploaded : " + fileName;
    }

    @GetMapping("/download")
    public S3Object downloadFile(@RequestParam("test.txt") String fileName) {
        return s3Client.getObject(bucketName, fileName);
    }

    private File convertMultiPartFileToFile(MultipartFile file) throws IOException {
        File convertedFile = new File(file.getOriginalFilename());
        FileOutputStream fos = new FileOutputStream(convertedFile);
        fos.write(file.getBytes());
        fos.close();
        return convertedFile;
    }
}
