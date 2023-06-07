/*
 * Toolbox of functions for creating visual memory experiments in js
 *
 */
var objects=new Array();
var selAng = null;
// Make and draw basic objects

function makeLine(id,x1,y1,x2,y2,color,linewidth){
    linewidth = typeof linewidth !== 'undefined' ? linewidth : 2.5;
    color = typeof color !== 'undefined' ? color : '#000000';
    line=new Object();
    line.id=id;
    line.x1=x1;
    line.x2=x2;
    line.y1=y1;
    line.y2=y2;
    line.color=color;
    line.linewidth=linewidth;
    line.type='line';
    objects.push(line);
    return line;
}

function drawLine(ctx,line){
    ctx.beginPath();
    ctx.lineWidth=line.linewidth;
    ctx.strokeStyle=line.color;
    ctx.moveTo(line.x1,line.y1);
    ctx.lineTo(line.x2,line.y2);
    ctx.stroke();
}

function makeText(id,x,y,words,color,style){
    style = typeof style !== 'undefined' ? style : "12px Arial";
    color = typeof color !== 'undefined' ? color : "Black";;
    text=new Object();
    text.id=id;
    text.x=x;
    text.y=y;
    text.color = color;
    text.style = style;
    text.words=words;
    text.type='text';
    objects.push(text);
    return text;
}

function drawText(ctx,text){
    ctx.fillStyle = text.color;
    ctx.font = text.style;
    ctx.fillText(text.words, text.x, text.y);
}

function makeCircle(id,x,y,radius,canMove,lineWidth,color,lineCol,arc1,arc2){
     lineWidth = typeof lineWidth !== 'undefined' ? lineWidth : 0;
     lineCol = typeof lineCol !== 'undefined' ? lineCol : '#000000';
     color = typeof color !== 'undefined' ? color : '#000000';
     arc1 = typeof arc1 !== 'undefined' ? arc1 : 0;
     arc2 = typeof arc2 !== 'undefined' ? arc2 : Math.PI*2;
     canMove = typeof canMove !== 'undefined' ? canMove : false;

     circle=new Object();
     circle.id=id;
     circle.x=x;
     circle.y=y;
     circle.radius=radius;
     circle.color=color;
     circle.lineCol=lineCol;
     circle.lineWidth=lineWidth;
     circle.arc1=arc1;
     circle.arc2=arc2;
     circle.canMove=canMove;
     circle.type='circle';
     objects.push(circle)
     return circle;
}

function drawCircle(ctx,circle){
    // Draw circle outline
     ctx.beginPath();
     ctx.arc(circle.x, circle.y, circle.radius+circle.lineWidth, circle.arc1, circle.arc2, false);
     ctx.lineTo(circle.x,circle.y);
     ctx.fillStyle = circle.lineCol;
     ctx.fill();
     ctx.lineWidth = circle.lineWidth;

     // Draw circle fill
     ctx.strokeStyle=circle.color;
     ctx.fillStyle=circle.color;
     ctx.beginPath();
     ctx.arc(circle.x, circle.y, circle.radius, circle.arc1, circle.arc2, false);
     ctx.lineTo(circle.x,circle.y);
     ctx.fillStyle = circle.color;
     ctx.fill();
     ctx.lineWidth = 0;
     ctx.stroke();
     ctx.closePath();
     return circle;
}

function drawCircle2(ctx,circle){
     // Draw circle fill
     ctx.strokeStyle=circle.color;
     ctx.fillStyle=circle.color;
     ctx.beginPath();
     ctx.arc(circle.x, circle.y, circle.radius, circle.arc1, circle.arc2, false);
     ctx.lineTo(circle.x,circle.y);
     ctx.fillStyle = circle.color;
     ctx.fill();
     ctx.lineWidth = 0;
     ctx.stroke();
     return circle;
}

function overlapCircle(x,y,circle){
    dist=Math.pow(Math.pow(circle.x-x,2)+Math.pow(circle.y-y,2),.5);
    if (dist<=circle.radius){
        return true;
    }else{
        return false;
    }
}


function makeRectangle(id,x,y,width,height,canMove,color,lineCol,lineWidth,rot){
     canMove = typeof canMove !== 'undefined' ? canMove : false;
     color = typeof color !== 'undefined' ? color : '#000000';
     lineCol = typeof lineCol !== 'undefined' ? lineCol : '#000000';
     lineWidth = typeof lineWidth !== 'undefined' ? lineWidth : 0;
     rot = typeof rot !== 'undefined' ? rot : 0;


     rectangle=new Object();
     rectangle.id=id;
     rectangle.x=x;
     rectangle.y=y;
     rectangle.width=width;
     rectangle.height=height;
     rectangle.color=color;
     rectangle.rot=rot;
     rectangle.canMove=canMove
     rectangle.type='rectangle';
     objects.push(rectangle)
     return rectangle;
}

function overlapRectangle(x,y,rectangle){
    x2=x-rectangle.x;
    y2=y-rectangle.y;

    xBound=(x>=rectangle.x-rectangle.width/2 & x<=rectangle.x+rectangle.width/2) | (x<=rectangle.x-rectangle.width/2 & x>=rectangle.x+rectangle.width/2);
    yBound=(y>=rectangle.y-rectangle.height/2 & y<=rectangle.y+rectangle.height/2) | (y<=rectangle.y-rectangle.height/2 & y>=rectangle.y+rectangle.height/2)
    if(xBound & yBound){
        return true;
    }else{
        return false;
    }
}

function makeCrosshair(){
            // Draw rectangles
                makeRectangle('cross1',centerX,centerY,4,12,false,'#000000','#000000');
                makeRectangle('cross2',centerX,centerY,12,4,false,'#000000','#000000');
        }
function makeCrosshaircol(col){
            // Draw rectangles
                makeRectangle('cross1',centerX,centerY,4,12,false,col,col);
                makeRectangle('cross2',centerX,centerY,12,4,false,col,col);
        }
function drawRectangle(ctx,rectangle){
     ctx.fillStyle=rectangle.color;
     ctx.translate(rectangle.x, rectangle.y);
     ctx.rotate(rectangle.rot*Math.PI/180);
     ctx.translate(-rectangle.x, -rectangle.y);
     ctx.fillRect(rectangle.x-rectangle.width/2,rectangle.y-rectangle.height/2,rectangle.width,rectangle.height);


     ctx.translate(rectangle.x, rectangle.y);
     ctx.rotate(-rectangle.rot*Math.PI/180);
     ctx.translate(-rectangle.x, -rectangle.y);
}

function makeIm(id,x,y,width,height,file,canMove,rot){
    rot = typeof rot !== 'undefined' ? rot : 0;
    canMove = typeof canMove !== 'undefined' ? canMove : false;
    image=new Object();
    image.id=id;
    image.x=x;
    image.y=y;
    image.width=width;
    image.height=height;
    image.canMove=canMove;
    thisfile = file;
    image.file=thisfile;
    image.rot=rot;
    image.type='image';
    // objects.push(image);
    return image;
}



function drawIm(ctx,image,border){
    im=new Image();
    const thisim = image;
    im.src=thisim.file;

    im.onload = function(){

        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);

        ctx.drawImage(im, thisim.x-thisim.width/2, thisim.y-thisim.height/2,thisim.width,thisim.height);

        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(-thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);
    };


}

function drawIma(ctx,image,border){
    ima=new Image();
    const thisim = image;
    ima.src=thisim.file;

    ima.onload = function(){

        ctx.beginPath();
        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);

        ctx.drawImage(ima, thisim.x-thisim.width/2, thisim.y-thisim.height/2,thisim.width,thisim.height);

        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(-thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);


    };


}
function drawImb(ctx,image,border){
    imb=new Image();
    const thisim = image;
    imb.src=thisim.file;

    imb.onload = function(){

        ctx.beginPath();
        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);

        ctx.drawImage(imb, thisim.x-thisim.width/2, thisim.y-thisim.height/2,thisim.width,thisim.height);

        ctx.translate(thisim.x, thisim.y);
        ctx.rotate(-thisim.rot*Math.PI/180);
        ctx.translate(-thisim.x, -thisim.y);

        ctx.beginPath();
        ctx.rect(centerX-2,centerY-6,4,12);
        ctx.rect(centerX-6,centerY-2,12,4);
        ctx.fillStyle="#000000";
        ctx.fill();

    };


}

function makeTriangle(id,x,y,width,height,canMove,color,rot){
     canMove = typeof canMove !== 'undefined' ? canMove : '#000000';
     color = typeof color !== 'undefined' ? color : '#000000';
     rot = typeof rot !== 'undefined' ? rot : 0;

     triangle=new Object();
     triangle.id=id;
     triangle.x=x;
     triangle.y=y;
     triangle.width=width;
     triangle.height=height;
     triangle.color=color;
     triangle.rot=rot;
     triangle.type='triangle';
     triangle.canMove=canMove;
     objects.push(triangle)
     return triangle
}

function drawTriangle(ctx,triangle){
     ctx.fillStyle=triangle.color;
     ctx.translate(triangle.x, triangle.y);
     ctx.rotate(triangle.rot*Math.PI/180);
     ctx.translate(-triangle.x, -triangle.y);

     botLeftX=triangle.x-triangle.width/2;
     botLeftY=triangle.y-triangle.height/2;
     botRightX=triangle.x+triangle.width/2;
     botRightY=triangle.y-triangle.height/2;
     topX=triangle.x;
     topY=triangle.y+triangle.height/2;

     ctx.beginPath();
     ctx.moveTo(botLeftX,botLeftY);
     ctx.lineTo(botRightX,botRightY);
     ctx.lineTo(topX,topY);
     ctx.closePath();
     ctx.fill();

     ctx.translate(triangle.x, triangle.y);
     ctx.rotate(-triangle.rot*Math.PI/180);
     ctx.translate(-triangle.x, -triangle.y);
}

function overlapTriangle(x,y,triangle){
    slopeH=triangle.height/(triangle.width/2)
    slopeW=triangle.width/(triangle.height/2)
    x2=x-triangle.x;
    y2=y-triangle.y;
    xBound=(x2<=y2*slopeH & x2>=-y2*slopeH) | (x2>=y2*slopeH & x2<=-y2*slopeH);
    yBound=(y2<=(triangle.height/2) & y2>=-(triangle.height/2)) | (y2>=(triangle.height/2) & y2<=-(triangle.height/2));
    if(xBound & yBound){
        return true;
    }else{
        return false;
    }
}

function drawObjects(ctx,objects){
    for(i=0;i<objects.length;i++){
        if(objects[i].type=='circle'){
            drawCircle(ctx,objects[i])

        }else if(objects[i].type=='triangle'){
            drawTriangle(ctx,objects[i])
        }else if(objects[i].type=='line'){
            drawLine(ctx,objects[i])
        }else if(objects[i].type=='image'){
            drawIm(ctx,objects[i])
        }else if(objects[i].type=='rectangle'){
            drawRectangle(ctx,objects[i])
        }else if(objects[i].type=='text'){
            drawText(ctx,objects[i])
        }

    }

}

function drawGrid(ctx,numCol,numRow){
   numCol = typeof numCol !== 'undefined' ? numCol : 10;
   numRow = typeof numRow !== 'undefined' ? numRow : 5;
   ctx.fillStyle='#000000';
   ctx.strokeStyle='#000000';
   width=ctx.canvas.width;
   wShift=width/numCol;
   height=ctx.canvas.height;
   hShift=height/numRow;
   // Draw columns
   for(i=0;i<numCol;i++){
        ctx.beginPath();
        ctx.moveTo(wShift*i,0);
        ctx.lineTo(wShift*i,height);
        ctx.closePath();
        ctx.stroke()
        ctx.fillText(wShift*i,wShift*i,10)
   }
   for( j=0;j<numRow;j++){
        ctx.beginPath();
        ctx.moveTo(0,hShift*j);
        ctx.lineTo(width,hShift*j);
        ctx.closePath();
        ctx.stroke()
        ctx.fillText(hShift*j,5,hShift*j)
   }
}

function erase(ctx){
    width=ctx.canvas.width;
    height=ctx.canvas.height;
    ctx.fillStyle='#7f7f7f';
    ctx.fillRect(0,0,width,height);
}

function clear(){
    objects=new Array();
}

// Detect clicks
var sel=false;

// Allow rotations
var ad_KeyRotate=false;
var rotRate=10;

// Allow object movement
var mousemove_moveObject=true;

// Allow size changes
var ws_changeSize=false;
var heightRate=2.5;
var widthRate=2.5;
var radRate=2.5;


$(document).keypress(function(e) {

});

$(document).on("mousedown", function(e) {
    inBound=e.toElement.id=='myCanvas';
    hasMoved=moveLast>0;
    waitTime=endTime();
    hasWaited=waitTime>150;
    if(isTest & inBound & hasMoved & hasWaited){

        moveLast=0;
        rt.push(endTime());
        startTime();

        // currProbe++;
        erase(ctx1);
        clear();

        respLoc = [xdif,ydif]
        isTest = false;

        allcolAng.push(JSON.stringify(selAng));

        // document.getElementById('targ').value=JSON.stringify(color);
        document.getElementById('targAng').value=JSON.stringify(targAng);
        document.getElementById('respAng').value=JSON.stringify(selAng);
        document.getElementById('rt').value=JSON.stringify(rt);
        document.getElementById('movedEarly').value=JSON.stringify(movedEarly);
        if (requireMouseReturn) {
        needReset = true;
        }
            trialIsOver();
            //nextPage();
        // }
    }else if(isTrain){
        needReset = true;
        startTime();
        showPractice_f4_5()
    }

});

$(document).on("mouseup", function(e) {

});

$(document).on("mousemove", function(e) {
    // console.log(isTrain)
    inBound=e.toElement.id=='myCanvas';
    xdif=e.offsetX-centerX;
    ydif=e.offsetY-centerY;

    dist=Math.pow(Math.pow(xdif,2)+Math.pow(ydif,2),.5);
    // if (!isTest & !isTrain){
    //     // document.getElementById('instr').innerHTML='Dont move until Ring appears!';
    // }
    if (isStimPeriod & !isInstruct & dist>maxResetDist){
        movedEarly = 1
        $('#frame_warnMove').show();
    }
    if((isTest & inBound) | (isTrain&!needReset)){

        // xdif=e.offsetX-centerX;
        // ydif=e.offsetY-centerY;

        // dist=Math.pow(Math.pow(xdif,2)+Math.pow(ydif,2),.5);

        nubX=wheelRad*Math.cos(Math.acos(xdif/dist))
        nubY=wheelRad*Math.sin(Math.asin(ydif/dist))

        // From Tim B.
        // a = 9.0 + 50.0*cos(w/180*pi);
        // b = 9.0 + 50.0*sin(w/180*pi);

        wTemp= -Math.acos(xdif/dist);
        if(ydif>0){
            wTemp=2*Math.PI-wTemp;
        }
        selAng= wrap([(wTemp)*(180/Math.PI)],90)[0];

        if(selAng!=null){
            moveLast =1;
        }


        erase(ctx1);
        clear();
        makeColorWheelBW();
        // makeCrosshair();
        makeColorNub();
        // makeProbe(curprobe);
        // - makeNumberCue(curprobe) changed to make crosshair
        makeCrosshair();
        drawObjects(ctx1,objects);
    }
    else if (needReset & inBound &! isTrain){
        // xdif=e.offsetX-centerX;
        // ydif=e.offsetY-centerY;
        // dist=Math.pow(Math.pow(xdif,2)+Math.pow(ydif,2),.5);
        time_elapsed = endTime()
        if (dist<maxResetDist){
            
            isStimPeriod = false
            needReset = false;
            $('#frame_warnMove').hide();
            $('#frame_warnMoveBack').hide();
            startNextTrial()
            // startNextTrial()
        }else if (time_elapsed>warnSlowResetTime) {
            $('#frame_warnMoveBack').show();
        }}
    if (isTrain & needReset & inBound){
        
        if (dist<maxResetDist){
            isTrain = false;
            needReset = false;
            
            showPractice_f6()
        }
    }

});

function checkOverlap(x,y,objects){
    over=[]
    for(i=0;i<objects.length;i++){
        if(objects[i].type=='circle'){
            overlap=overlapCircle(x,y,objects[i])
        }else if(objects[i].type=='rectangle'){
            overlap=overlapRectangle(x,y,objects[i])
        }else if(objects[i].type=='triangle'){
            overlap=overlapTriangle(x,y,objects[i])
        }else if(objects[i].type=='image'){
            overlap=overlapRectangle(x,y,objects[i])
        }
        if(overlap){
            over.push(i);
        }
    }
    return over;
}

function feedback(thiserr){

          if (thiserr<=10){
              makeCrosshaircol('#b4fa84');
          }else if(thiserr<=25){
              makeCrosshaircol('#FFFF99');
          }else if(thiserr>25){
              makeCrosshaircol('#ff0000');
          }
        }

// Timing functions

function wait(time,func){
    setTimeout(function(){func},time);
}

// Probability

function normRand() {
    var x1, x2, rad;

    do {
        x1 = 2 * Math.random() - 1;
        x2 = 2 * Math.random() - 1;
        rad = x1 * x1 + x2 * x2;
    } while(rad >= 1 || rad == 0);

    var c = Math.sqrt(-2 * Math.log(rad) / rad);

    return x1 * c;
};

function changeInnerHTML(id,text){
            document.getElementById(id).innerHTML=text;
}

// Load multiple images
// http://www.html5canvastutorials.com/tutorials/html5-canvas-image-loader/
function loadImages(sources, callback) {
    var images = {};
    var loadedImages = 0;
    var numImages = 0;
    // get num of sources
    for(var src in sources) {
        numImages++;
    }
    for(var src in sources) {
        images[src] = new Image();
        images[src].onload = function() {
            if(++loadedImages >= numImages) {
                callback(images);
            }
        };
      images[src].src = sources[src];
    }
    return images;
}


function loadImages2(){
// Insert code that actually loads images
}

function nextPage(){
    document.nextpage.submit();
}

function angle2HEX(wholeDegree){

    w=wholeDegree*(Math.PI/180); // Round to integer degree
    l=65;
    a = 9.0 + 50.0*Math.cos(w);
    b = 9.0 + 50.0*Math.sin(w);
    image=[l,a,b];

    whitePoint = [0.950456,1,1.088754];

    fY=(image[0]+16)/116;
    fX=fY+image[1]/500;
    fZ=fY-image[2]/200

    function invf(fi){
        Y=Math.pow(fi, 3);
        i=(Y<.008856);
        if(i){
            Y=(fi-(4/29))*(108/841);
        }
        return Y;
    }

//           Convert from cie lab to cie xyz
//           fY = (Image(:,:,1) + 16)/116;
//            fX = fY + Image(:,:,2)/500;
//            fZ = fY - Image(:,:,3)/200;
//            Image(:,:,1) = WhitePoint(1)*invf(fX);  % X
//            Image(:,:,2) = WhitePoint(2)*invf(fY);  % Y
//            Image(:,:,3) = WhitePoint(3)*invf(fZ);  % Z
// invf
//          Y = fY.^3;
//          i = (Y < 0.008856);
//          Y(i) = (fY(i) - 4/29)*(108/841);

    image2=[];
    image2[0]=whitePoint[0]*invf(fX);
    image2[1]=whitePoint[1]*invf(fY);
    image2[2]=whitePoint[2]*invf(fZ);



//   T = [3.240479,-1.53715,-0.498535;-0.969256,1.875992,0.041556;0.055648,-0.204043,1.057311];
//   R = T(1)*Image(:,:,1) + T(4)*Image(:,:,2) + T(7)*Image(:,:,3);  % R
//   G = T(2)*Image(:,:,1) + T(5)*Image(:,:,2) + T(8)*Image(:,:,3);  % G
//   B = T(3)*Image(:,:,1) + T(6)*Image(:,:,2) + T(9)*Image(:,:,3);  % B
    T=[3.240479,-0.969256,0.055648,-1.53715,1.875992,-0.204043,-0.498535,0.041556,1.057311];
    R = T[0]*image2[0] + T[3]*image2[1] + T[6]*image2[2];
    G = T[1]*image2[0] + T[4]*image2[1] + T[7]*image2[2];
    B = T[2]*image2[0] + T[5]*image2[1] + T[8]*image2[2];

//   % Desaturate and rescale to constrain resulting RGB values to [0,1]
//   AddWhite = -min(min(min(R,G),B),0);
//   Scale = max(max(max(R,G),B)+AddWhite,1);
//   R = (R + AddWhite)./Scale;
//   G = (G + AddWhite)./Scale;
//   B = (B + AddWhite)./Scale;

    AddWhite = -Math.min(Math.min(Math.min(R,G),B),0);
    Scale = Math.max(Math.max(Math.max(R,G),B)+AddWhite,1);
    R = (R + AddWhite)/Scale;
    G = (G + AddWhite)/Scale;
    B = (B + AddWhite)/Scale;

//  function Rp = gammacorrection(R)
//  Rp = real(1.099*R.^0.45 - 0.099);
//  i = (R < 0.018);
//  Rp(i) = 4.5138*R(i);
    function gammacorrection(R){
        Rp=(1.099*Math.pow(R,0.45) - 0.099);// See if we need the real function
        i=R<.018
        if(i){
            Rp=4.5138*R
        }
        return Rp;
    }

//   % Apply gamma correction to convert RGB to Rec. 709 R'G'B'
//   Image(:,:,1) = gammacorrection(R);  % R'
//   Image(:,:,2) = gammacorrection(G);  % G'
//   Image(:,:,3) = gammacorrection(B);  % B'

    newColorRGB=[];
    newColorRGB[0]=gammacorrection(R);
    newColorRGB[1]=gammacorrection(G);
    newColorRGB[2]=gammacorrection(B);

    function componentToHex(c) {
        var hex = c.toString(16);
        return hex.length == 1 ? "0" + hex : hex;
    }

    function rgbToHex(r, g, b) {
        return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }


    newColorHex=rgbToHex(Math.round(255*newColorRGB[0]), Math.round(255*newColorRGB[1]), Math.round(255*newColorRGB[2]));

    return newColorHex;
}
