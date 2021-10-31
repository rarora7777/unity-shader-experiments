using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class StrokeGeometry : MonoBehaviour
{
    // Start is called before the first frame update

    MeshFilter mf;
    Material mat;
    Vector3[] normals;
    
    public Vector3[] verts;
    public enum StrokeType { Plane = 0, Sphere = 1};
    public StrokeType strokeType;
    public float strokeWidth = 0.02f;

    private struct ShaderPropertyIDs
    {
        public int _StrokeType;
        public int _StrokeWidth;
    }
    private ShaderPropertyIDs shaderPropIds;


    void Start()
    {
        mat = GetComponent<MeshRenderer>().material;
        GetComponent<MeshRenderer>().material = mat;
        mf = GetComponent<MeshFilter>();
        mf.sharedMesh = new Mesh();

        shaderPropIds = new ShaderPropertyIDs()
        {
            _StrokeType = Shader.PropertyToID("_StrokeType"),
            _StrokeWidth = Shader.PropertyToID("_StrokeWidth")
        };

        mat.SetInt(shaderPropIds._StrokeType, (int)strokeType);
        mat.SetFloat(shaderPropIds._StrokeWidth, strokeWidth);

        int n = 100;
        float fn = n;
        verts = new Vector3[n+1];
        Vector3 origin = new Vector3(2, 2, 0);
        float radius = 0.5f;
        for (int i=0; i<verts.Length; ++i)
        {
            
            verts[i] = origin + radius * new Vector3(
                Mathf.Cos(2.0f*Mathf.PI * i / fn), 
                0.0f, 
                Mathf.Sin(2.0f*Mathf.PI * i / fn));
        }
    }

    // Update is called once per frame
    void Update()
    {
        var mesh = mf.sharedMesh;

        mesh.vertices = verts;
        int[] tris = new int[3 * (verts.Length - 1)];
        for(int i=0; i<verts.Length-1; ++i)
        {
            tris[3 * i + 0] = i;
            tris[3 * i + 1] = i + 1;
            tris[3 * i + 2] = i + 1;
        }
        mesh.triangles = tris;

        mat.SetInt(shaderPropIds._StrokeType, (int)strokeType);
        mat.SetFloat(shaderPropIds._StrokeWidth, strokeWidth);
    }
}
