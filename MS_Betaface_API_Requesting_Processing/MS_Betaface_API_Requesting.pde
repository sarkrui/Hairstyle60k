import http.requests.*;

import org.neuroph.core.*;
import org.neuroph.core.data.*;
import org.neuroph.core.data.norm.*;
import org.neuroph.core.data.sample.*;
import org.neuroph.core.events.*;
import org.neuroph.core.exceptions.*;
import org.neuroph.core.input.*;
import org.neuroph.core.learning.error.*;
import org.neuroph.core.learning.*;
import org.neuroph.core.learning.stop.*;
import org.neuroph.core.transfer.*;
import org.neuroph.nnet.*;
import org.neuroph.nnet.comp.*;
import org.neuroph.nnet.comp.layer.*;
import org.neuroph.nnet.comp.neuron.*;
import org.neuroph.nnet.learning.*;
import org.neuroph.util.benchmark.*;
import org.neuroph.util.*;
import org.neuroph.util.io.*;
import org.neuroph.util.plugins.*;
import org.neuroph.util.random.*;

import java.util.*;

//curl -v -X POST "https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=false&returnFaceAttributes={string}"
//-H "Content-Type: application/json"
//-H "Ocp-Apim-Subscription-Key: {subscription key}"
//--data-ascii "{body}" 

import http.requests.*;
PrintWriter output;
JSONArray msResponse;
JSONArray betafaceResponse;
JSONObject faceAttributes;

float[] remapped = new float[20];
int remapped_gender = 0;
float remapped_glasses = 0;
float remapped_age;
float sideburns = 0;
float beard = 0;
float moustache = 0;

void getMS() {

  msResponse = new JSONArray();
  faceAttributes = new JSONObject();
  
  //Creates a json file in the sketch directory to store JSON response from Microsoft FaceAPI
  output = createWriter("msResponse.json");
  
  //HTTP Request body
  PostRequest post = new PostRequest("https://northeurope.api.cognitive.microsoft.com/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=false&returnFaceAttributes=gender,age,facialHair,glasses");
  post.addHeader("Host", "northeurope.api.cognitive.microsoft.com");
  post.addHeader("Content-Type", "application/json");
  post.addHeader("Ocp-Apim-Subscription-Key", "5f1a14d290b54640804ee44a94548c66");
  post.addJson("{\"url\":\"https://raw.githubusercontent.com/sarkrui/Hairstyle60k/master/Dataset/Curly/IMG_1.jpg\"}");
  post.send();
  
  //Parse HTTP Response as a JSON Array
  JSONArray msResponse = parseJSONArray(post.getContent());
  
  //Saves JSON Array to local for backup
  saveJSONArray(msResponse, "data/msResponse.json");
 
  //Reads local JSON file
  //msResponse = loadJSONArray("data/msResponse.json");
  
  //"Gender","Age","Moustache","Beard","Sideburns","Glasses"
  
  //Expands JSONArray msResponse[0]
  JSONObject msObject = msResponse.getJSONObject(0);
  
  //Expands JSONObject faceAttributes
  JSONObject faceAttributes = msObject.getJSONObject("faceAttributes");
  
  //Expands JSONObject facialHair
  JSONObject facialHair = faceAttributes.getJSONObject("facialHair");
  
  //Expands JSONObject faceAttributes
  String glasses = faceAttributes.getString("glasses");
  String gender = faceAttributes.getString("gender"); 
  int age = faceAttributes.getInt("age"); 
  
  //Retrieves a String value from
  sideburns = facialHair.getFloat("sideburns"); 
  beard = facialHair.getFloat("beard");
  moustache = facialHair.getFloat("moustache");
  
  //gender:
  if(gender == "female"){
    remapped_gender = 0;
  }else if (gender == "male"){
    remapped_gender = 1;
  }
  
  //glasses:
  if(glasses == "noGlasses"){
    remapped_glasses = 0;
  }else if (glasses == "ReadingGlasses"){
    remapped_glasses = 0.5;
  }else{
    remapped_glasses = 1;
  }
  
  //age:
  remapped_age = age/100.0;
  
  //JSONObject faceAttributes = MS_Object.getJSONObject(1);
  //String Age = faceAttributes.getString("glasses");
  //String Moustache = faceAttributes.getString("moustache");
  println(remapped_gender,"\n",remapped_age,"\n",moustache,"\n",beard,"\n",sideburns,"\n",remapped_glasses);
}

//curl -sS https://www.betafaceapi.com/api/v2/media -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"api_key\": \"d45fd466-51e2-4701-8da8-04351c872236\", \"file_uri\": \"https://raw.githubusercontent.com/sarkrui/Hairstyle60k/master/Dataset/${STYLE[$i]}/IMG_$INDEX.jpg\", \"detection_flags\": \"classifiers\"}"
//https://raw.githubusercontent.com/sarkrui/Hairstyle60k/master/Dataset/Curly/IMG_39.jpg
//import http.requests.*;

void getBetaface() {
  
  betafaceResponse = new JSONArray();
  
  //Declares the reading order from tags
  int[] readingOrder = {27,0,2,4,6,7,8,9,14,16,22,23,26,28,35,36,44,54,66,69};
  
  PostRequest post = new PostRequest("https:" + "//www.betafaceapi.com/api/v2/media");
  post.addHeader("accept", "application/json");
  post.addHeader("Content-Type", "application/json");
  post.addJson("{\"api_key\": \"d45fd466-51e2-4701-8da8-04351c872236\",\"file_uri\": \"https://raw.githubusercontent.com/sarkrui/Hairstyle60k/master/Dataset/Curly/IMG_1.jpg\",\"detection_flags\": \"classifiers,extended\"}");
  post.send();
  
  //System.out.println(post.getContent() + "\n");
  
  //Parse HTTP Response as a JSON Array
  JSONObject betafaceResponse = parseJSONObject(post.getContent());
  
  //Saves JSON Array to local
  saveJSONObject(betafaceResponse, "data/betafaceResponse.json");
  
  //Expands JSONObject media
  JSONObject media = betafaceResponse.getJSONObject("media");
  
  //Store JSONArray faces
  JSONArray faces = media.getJSONArray("faces");
  
  //Expands JSONArray faces
  JSONObject face = faces.getJSONObject(0);

  //Expands JSONObject face
  JSONArray tags = face.getJSONArray("tags");
  
  //float[] remapped = new float[20];
  
  for (int i = 0; i < 20; i++) {
  
    //Expands JSONArray tags
    JSONObject feature = tags.getJSONObject(readingOrder[i]);
    
    //Expands JSONObject feature
    float confidence = feature.getFloat("confidence");
    String name = feature.getString("name");
    String value = feature.getString("value");
    
    if(value == "yes"){
      remapped[i] = 0.5 + confidence/2.0;
    } else if(value == "no"){
      remapped[i] = 0.5 - confidence/2.0;
    }else {
      remapped[i] = confidence;
    }
    
    if(value == "extra small"){
      remapped[i] = 0;
    }else if(value == "small"){
      remapped[i] = 0.25;
    }else if(value == "average"){
      remapped[i] = 0.5;
    }else if(value == "big"){
      remapped[i] = 0.75;
    }else if(value == "extra big"){
      remapped[i] = 1;
    }else{
      remapped[i] = confidence;
    }
    
    if(value == "extra narrow"){
      remapped[i] = 0;
    }else if(value == "narrow"){
      remapped[i] = 0.25;
    }else if(value == "average"){
      remapped[i] = 0.5;
    }else if(value == "wide"){
      remapped[i] = 0.75;
    }else if(value == "extra wide"){
      remapped[i] = 1;
    }else{
      remapped[i] = confidence;
    }
    
    if(value == "extra close"){
      remapped[i] = 0;
    }else if(value == "close"){
      remapped[i] = 0.25;
    }else if(value == "average"){
      remapped[i] = 0.5;
    }else if(value == "far"){
      remapped[i] = 0.75;
    }else if(value == "extra far"){
      remapped[i] = 1;
    }else{
      remapped[i] = confidence;
    }
    
    println(name,remapped[i]);
    
  }
} 

PImage img;
String str = new String();

String output_category[] = {"Aaron_Kwok","Afro","Bald","Beehive","Bob","Bouffant","Bowl_Cut","Bun","Caesar","Chonmage","Comb_Over","Cornrows","Crew_Cut","Crop","Croydon_Facelift","Curly","Curly_Hair","Curtained_Hair","Cute_Ponytails","Dreadlocks","Emo_hair","Fauxhawk","Flattop","French_Braid","Hi-top_Fade","Hime_Cut","Induction_Cut","Jimmy_Lin_Hairstyle","Layered_Hair","Liberty_Spikes_Hair","Medium-Length_Hair","Men_Pompadour","Men_With_Square_Angles","Mohawk","Mop-Top_Hair","Mullet","Odango_Hair","Pageboy","Perm","Pixie_Cut","Ponytail","Razor_Cut","Ringlet","Shag","Shoulder-Length_Hair","Side_Part","Slicked-back","Spiky_Hair","Tapered_Sides","The_Rachel","Updo","Waist-Length_Hair","Wave_Hair"};
String[] topThree = new String[3];
float[] topData = new float[3];

void setup(){
  size(1400,720);
  img = loadImage("image.jpeg");
  
  getMS();
  getBetaface();
  
  // load saved neural network
  NeuralNetwork neuralNetwork1 = NeuralNetwork.createFromFile(sketchPath("myMlPerceptron.nnet"));
  
  // set network input
  neuralNetwork1.setInput(remapped_gender,remapped_age,moustache,beard,sideburns,remapped_glasses,remapped[0],remapped[1],remapped[2],remapped[3],remapped[4],remapped[5],remapped[6],remapped[7],remapped[8],remapped[9],remapped[10],remapped[11],remapped[12],remapped[13],remapped[14],remapped[15],remapped[16],remapped[17],remapped[18], remapped[19]);
  // calculate network
  neuralNetwork1.calculate();
  
  // get network output
  double[] networkOutput = neuralNetwork1.getOutput();
  System.out.println(" Output: " + Arrays.toString(networkOutput) );
    str = Arrays.toString(networkOutput);
  
  for(int i = 0; i < 53; i ++ ){
    int n = 0;
    for(int j = 0; j < 53; j ++){
      if(networkOutput[i] < networkOutput[j])
      n ++;
    }
    if(n == 0){
      topThree[0] = output_category[i];
      topData[0] = (float)networkOutput[i];
      n = 0;
    }
    else if(n == 1){
      topThree[1] = output_category[i];
      topData[1] = (float)networkOutput[i];
      n = 0;
    }
    else if(n == 2){
      topThree[2] = output_category[i];
      topData[2] = (float)networkOutput[i];
      n = 0;
    }
    else n = 0;
  }
  
  for(int i = 0; i < 3; i ++){
    println(topThree[i]);
  }
}

void draw(){
  image(img, 0, 0, 540, 720);
  
  textSize(30);
  fill(0);
  textAlign(CENTER);
  text("HAIR RECOMMENDATION", 1000, 50);
  
  textSize(40);
  fill(0);
  textAlign(CENTER);
  text(topThree[0]+": "+topData[0], 1000, 160);
  text(topThree[1]+": "+topData[1], 1000, 290);
  text(topThree[2]+": "+topData[2], 1000, 420);
  
  textSize(10);
  textAlign(LEFT);
  text(str, 580, 520, 800, 720);
}
