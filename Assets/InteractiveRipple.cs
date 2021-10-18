using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractiveRipple : MonoBehaviour
{

    private Material material;
    private Color prevColour;

    private struct ShaderPropertyIDs
    {
        public int _BaseColour;
        public int _RippleColour;
        public int _RippleCenter;
        public int _RippleCenterUV;
        public int _RippleStartTime;
    }
    private ShaderPropertyIDs shaderPropIds;

    // Start is called before the first frame update
    void Start()
    {
        material = GetComponent<MeshRenderer>().material;

        shaderPropIds = new ShaderPropertyIDs()
        {
            _BaseColour = Shader.PropertyToID("_BaseColour"),
            _RippleColour = Shader.PropertyToID("_RippleColour"),
            _RippleCenter = Shader.PropertyToID("_RippleCenter"),
            _RippleCenterUV = Shader.PropertyToID("_RippleCenterUV"),
            _RippleStartTime = Shader.PropertyToID("_RippleStartTime")
        };

        prevColour = material.GetColor(shaderPropIds._BaseColour);
        material.SetColor(shaderPropIds._RippleColour, prevColour);
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            CastClickRay();
        }
        
    }

    private void CastClickRay()
    {
        var camera = Camera.main;
        var mousePos = Input.mousePosition;

        var ray = camera.ScreenPointToRay(new Vector3(mousePos.x, mousePos.y, camera.nearClipPlane));

        if (Physics.Raycast(ray, out var hit) && hit.collider.gameObject == gameObject)
        {
            StartRipple(hit);
        }
    }

    private void StartRipple(RaycastHit hit)
    {
        Vector3 center = hit.point;
        Vector2 centerUV = hit.textureCoord;

        Color rippleColour = Color.HSVToRGB(Random.value, 1, 1);

        material.SetVector(shaderPropIds._RippleCenter, center);
        material.SetVector(shaderPropIds._RippleCenterUV, centerUV);
        material.SetFloat(shaderPropIds._RippleStartTime, Time.time);

        material.SetColor(shaderPropIds._BaseColour, prevColour);
        material.SetColor(shaderPropIds._RippleColour, rippleColour);

        prevColour = rippleColour;
    }
}
