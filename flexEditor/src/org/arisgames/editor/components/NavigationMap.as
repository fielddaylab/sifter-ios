package org.arisgames.editor.components
{
import com.google.maps.LatLng;
import com.google.maps.Map3D;
import com.google.maps.MapAction;
import com.google.maps.MapEvent;
import com.google.maps.MapOptions;
import com.google.maps.MapType;
import com.google.maps.View;
import com.google.maps.controls.MapTypeControl;
import com.google.maps.controls.NavigationControl;
import com.google.maps.geom.Attitude;
import com.google.maps.overlays.MarkerOptions;
import com.google.maps.services.ClientGeocoder;
import com.google.maps.services.GeocodingEvent;

import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.Image;
import mx.core.DragSource;
import mx.core.IUIComponent;
import mx.events.DragEvent;
import mx.events.DynamicEvent;
import mx.managers.DragManager;
import mx.rpc.Responder;

import org.arisgames.editor.data.PlaceMark;
import org.arisgames.editor.data.arisserver.Location;
import org.arisgames.editor.data.businessobjects.ObjectPaletteItemBO;
import org.arisgames.editor.models.GameModel;
import org.arisgames.editor.services.AppServices;
import org.arisgames.editor.util.AppConstants;
import org.arisgames.editor.util.AppDynamicEventManager;
import org.arisgames.editor.util.AppUtils;

// Handles most of the interfacing with the Google Map APIs
public class NavigationMap extends Map3D
{
    private var markers:ArrayCollection;

    public function NavigationMap()
    {
        super();
        this.key = AppConstants.APPLICATION_ENVIRONMENT_GOOGLEMAP_KEY;
		this.sensor = "false";
        addEventListener(MapEvent.MAP_PREINITIALIZE, onMapPreinitialize);
        addEventListener(MapEvent.MAP_READY, onMapReady);
//        addEventListener(MapMouseEvent.DOUBLE_CLICK, processMapDoubleClick);
        markers = new ArrayCollection();
        trace("In NavigationMap constructor...");
    }

    private function onMapPreinitialize(event:MapEvent):void
    {
        trace("onMapPreinstall being run.");
        var myMapOptions:MapOptions = new MapOptions;
        myMapOptions.zoom = 12;
        myMapOptions.viewMode = View.VIEWMODE_ORTHOGONAL;
//        myMapOptions.attitude = new Attitude(20, 30, 0);
        this.setInitOptions(myMapOptions);
    }

    private function onMapReady(event:MapEvent):void
    {
        trace("onMapReady is being called.");
        AppDynamicEventManager.getInstance().addEventListener(AppConstants.DYNAMICEVENT_PLACEMARKREQUESTSDELETION, deletePlaceMarker)

        var latLng:LatLng = new LatLng(39.57182223734374, -95.9765625);
        setCenter(latLng, 4, MapType.NORMAL_MAP_TYPE);

        addControl(new NavigationControl());
        addControl(new MapTypeControl());

        // Disable double click zoom as map is using double click for marker placement
//        this.setDoubleClickMode(MapAction.ACTION_NOTHING);
        this.enableScrollWheelZoom();
        this.enableContinuousZoom();

        // Load Any PlaceMarks in data model
        this.handlePlaceMarkModelChanges(null);

        // Add listener to Game model
        AppDynamicEventManager.getInstance().addEventListener(AppConstants.APPLICATIONDYNAMICEVENT_GAMEPLACEMARKSLOADED, handlePlaceMarkModelChanges);
    }

    private function handlePlaceMarkModelChanges(de:DynamicEvent):void
    {
        trace("NavigationMap: handlePlaceMarkModelChanges");
        // Remove All Current Markers
        for (var j:Number = 0; j < markers.length; j++)
        {
            var m:PlaceMarker = markers.getItemAt(j) as PlaceMarker;
            this.removeOverlay(m);
        }
        markers.removeAll();

        trace("game model place marks number = " + GameModel.getInstance().game.placeMarks.length);
        for (j = 0; j < GameModel.getInstance().game.placeMarks.length; j++)
        {
            var pm:PlaceMark = GameModel.getInstance().game.placeMarks.getItemAt(j) as PlaceMark;
            trace("j = " + j + "; pm lat = " + pm.latitude + "; pm lng = " + pm.longitude);
            addPlaceMarker(pm);
        }
        trace("Done with handlePlaceMarkModelChanges");
    }

    private function addPlaceMarker(pm:PlaceMark):void
    {
        trace("adding Place Marker with lat = " + pm.latitude + " lng = " + pm.longitude + "qrCode = " + pm.qrCode);
        var latLng:LatLng = new LatLng(pm.latitude, pm.longitude);
        var marker:PlaceMarker = new PlaceMarker(latLng, pm, this);
        addOverlay(marker);
        markers.addItem(marker);
    }

    public function deletePlaceMarker(evt:DynamicEvent):void
    {
        trace("NavMap.deletePlaceMarker() called...");
        // Remove From Database
        var pm:PlaceMark = evt.placeMark;
        if (pm == null)
        {
            trace("The placemark that was passed into be deleted was NULL.  Displaying error message to user and returning without deleting anything.");
            Alert.show("The location to delete was not handled properly by the application.  Please try to delete again.", "Error Removing Location");
            return;
        }
        trace("PlaceMark to delete has ID = '" + pm.id + "'; Name = '" + pm.name + "'");
        AppServices.getInstance().deleteLocation(GameModel.getInstance().game.gameId, pm.id, new Responder(handleDeleteLocation, handleFault));

        // Remove From Map and Client Data Model
        var m:PlaceMarker;
        var ri:Number = -1;
        for (var lc:Number = 0; lc < markers.length; lc++)
        {
            m = markers.getItemAt(lc) as PlaceMarker;
            if (m.placemark.id == pm.id)
            {
                trace("Found PlaceMarker at lc = '" + lc + "' to remove!");
                ri = lc;
                m.closeInfoWindow();
                m.hide();
                break;
            }
        }

        if (ri == -1)
        {
            trace("The placemark data WAS NOT found in the collection.  Will display error message to user.");
            Alert.show("There was an error trying to delete this location.  Please try again if the marker is still displayed on the game map.", "Error Deleting Placemark")
        }
        else
        {
            trace("Found the placemark data object in the collection, will remove it from the collection and display success message to user.");
            markers.removeItemAt(ri);
            Alert.show("Successfully removed '" + pm.name + "' marker from the map.", "Successfully Removed");
        }

        trace("NavMap.deletePlaceMarker() finished.");
    }

    private function handleDeleteLocation(obj:Object):void
    {
        trace("handleDeleteLocation() data service callback method called.");
        if (obj.result.returnCode != 0)
        {
            trace("Bad delete location (placemark) attempt... let's see what happened.");
            var msg:String = obj.result.returnCodeDescription;
            Alert.show("Error Was: " + msg, "Error While Deleting Placemark");
        }
        else
        {
            trace("The placemark / location was deleted properly in the database.");
        }
    }

    public function addPlaceMarkAsDefinedAtLatLng(pm:PlaceMark):void
    {
        trace("Begin processing addPlaceMarkAsDefinedAtLatLng with lat = '" + pm.latitude + "'; lon = '" + pm.longitude + "'");
        GameModel.getInstance().addPlaceMark(pm);
		
		//Visually update the map
        var marker:PlaceMarker = new PlaceMarker(new LatLng(pm.latitude, pm.longitude), pm, this);
        addOverlay(marker);
        markers.addItem(marker);
        trace("done processing setMarkerToLatLng");
    }

	private function createTextField(label:String, width:Number, height:Number, x:Number=5, y:Number=5):TextField
	{
		var labelMc:TextField=new TextField();
		labelMc.selectable=false;
		labelMc.border=false;
		labelMc.embedFonts=false;
		labelMc.mouseEnabled=false;
		labelMc.width=width;
		labelMc.height=height;
		labelMc.text=label;
		labelMc.autoSize=TextFieldAutoSize.CENTER;
		labelMc.x=x;
		labelMc.y=y;
		return labelMc;
	}	
	
	
    public function doFlyTo(geoText:String):void
    {
        // Instantiate a Geocoder
        var geocoder:ClientGeocoder = new ClientGeocoder();

        // Add an event listener for a GEOCODING SUCCESS
        geocoder.addEventListener(GeocodingEvent.GEOCODING_SUCCESS,
                function(event:GeocodingEvent):void
                {
                    var placemarks:Array = event.response.placemarks;
                    if (placemarks.length > 0)
                    {
                        flyTo(placemarks[0].point, 15, new Attitude(20, 30, 0), 3);
/*
                        var marker:Marker = new Marker(placemarks[0].point);
                        marker.addEventListener(MapMouseEvent.CLICK, function (event:MapMouseEvent):void
                        {
                            marker.openInfoWindow(new InfoWindowOptions({content: placemarks[0].address}));
                        });
                        addOverlay(marker);
*/
                    }
                }
        );

        geocoder.addEventListener(GeocodingEvent.GEOCODING_FAILURE,
                function(event:GeocodingEvent):void
                {
                    Alert.show("Couldn't find the location entered.", "Geocoding failed");
                    trace(event);
                    trace(event.status);
                }
        );

        geocoder.geocode(geoText);
    }

    public function paletteObjectDragEnterHandler(evt:DragEvent):void
    {
        trace("paletteObjectDragEnterHandler called.");

        // Find Out If It's a Tree Item
        if (evt.dragSource.hasFormat('treeItems'))
        {
            trace("This is tree data so continue");
        }
        else
        {
            trace("This isn't tree data so return.");
            return;
        }

        var itemsArray:Array = evt.dragSource.dataForFormat('treeItems') as Array;
        trace("itemsArray created with size = '" + itemsArray.length + "'");

        var obj:ObjectPaletteItemBO = itemsArray[0] as ObjectPaletteItemBO;
        trace("Got data object");

        if (!obj.isFolder())
        {
            trace("Data Object is not a Folder so allow the drop.");
            var dropTarget:IUIComponent = evt.currentTarget as IUIComponent;
            DragManager.acceptDragDrop(dropTarget);
        }
        else
        {
            trace("It's a Folder, so don't allow drop.");
        }
        trace("paletteObjectDragEnterHandler finished.");
    }

    public function paletteObjectDragExitHandler(evt:DragEvent):void
    {
        trace("paletteObjectDragExitHandler() called!");
    }

    public function paletteObjectDropHandler(evt:DragEvent):void
    {
        trace("paletteObjectDragDropHandler called!  New data tree looks like...");

        var ds:DragSource = evt.dragSource;

        var items:Array = ds.dataForFormat("treeItems") as Array;
        for (var i:Number = 0; i < items.length; i++)
        {
            var obj:ObjectPaletteItemBO = items[i];
            trace("obj name = '" + obj.name + "'");

            // Find Lat Lon On Map
            var ll:LatLng = this.fromViewportToLatLng(new Point(evt.localX, evt.localY));
            trace("Point X: " + evt.localX + "; Point Y: " +  evt.localY + "; Translates to LatLng = '" + ll + "'");

            var pm:PlaceMark = new PlaceMark();
			pm.objectPalletItemBO = obj;
            pm.contentId = obj.objectId;
            pm.latitude = ll.lat();
            pm.longitude = ll.lng();
            pm.name = obj.name;
            pm.errorRange = AppConstants.PLACEMARK_DEFAULT_ERROR_RANGE;
            pm.contentType = AppUtils.getContentTypeValueByName(obj.objectType);

            this.addPlaceMarkAsDefinedAtLatLng(pm);

            var loc:Location = new Location();
            loc.latitude = pm.latitude;
            loc.longitude = pm.longitude;
            loc.name = pm.name;
            loc.type = AppUtils.getContentTypeForDatabaseAsString(pm.contentType);
            loc.typeId = obj.objectId;
            loc.quantity = 1;
            loc.hidden = pm.hidden;
            loc.forceView = pm.forcedView;
			loc.quickTravel = pm.quickTravel;
            loc.error = pm.errorRange;
            trace("location type looked up = '" + loc.type + "' for Content Type Number = '" + pm.contentType + "'");

            AppServices.getInstance().saveLocation(GameModel.getInstance().game.gameId, loc, new Responder(handleCreateNewLocation, handleFault));

        }
        trace("paletteObjectDragDropHandler is finished.");
    }

    public function handleCreateNewLocation(obj:Object):void
    {
        trace("Result called with obj = " + obj + "; Result = " + obj.result);
        if (obj.result.returnCode != 0)
        {
            trace("Bad create location (placemark) attempt... let's see what happened.");
            var msg:String = obj.result.returnCodeDescription;
            Alert.show("Error Was: " + msg, "Error While Creating Placemark");
        }
        else
        {
            trace("Create Location (Placemark) was successfull");
            var pm:PlaceMarker;
            for(var lc:Number = 0; lc < markers.length; lc++)
            {
                pm = markers.getItemAt(lc) as PlaceMarker;
                if (isNaN(pm.placemark.id))
                {
                    pm.placemark.id = obj.result.data;
                    trace("Assigned newly created id to placemark data object.  Id = '" + pm.placemark.id + "' with Latitude = '" + pm.placemark.latitude + "'; Longitude = '" + pm.placemark.longitude + "'.");
                    break;
                }
            }
        }
    }

    public function handleFault(obj:Object):void
    {
        trace("Fault called...");
        Alert.show("Error occurred: " + obj.fault.faultString, "More problems..");
    }
}
}